require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	$id_to_fragment = Hash.new 	#used specifically to take in recieved fragments for SENDMSG
								# {segment_id -> array of fragments}

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[3]
		
		if ( dst == nil )
			return
		end

		if ($neighbors[dst] == nil)
			# Adds edge of COST 1 to DST
			$rt_table[dst] = [dst, 1]

			# Add edge to graph
			$graph.add_edge($hostname, dst, 1)
			
			# DST's port number
			dstPort = $nodes_map[dst]
			
			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$neighbors[dst] = [1, TCPSocket.open(msgParsed[2], dstPort)]
			
			# Send request to DST to add edge to its routing
			# table. Flip recieved command to do so.
			# Format: [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = "REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
			$neighbors[dst][1].puts(str_request)
		end
	end

	def self.edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[1]

		# Removes the edge between current node and DST
		# Closes socket connection between the two nodes
		$neighbors[dst][1].close
		$neighbors.delete(dst)
		
		# Remove edge from graph
		$graph.remove_edge($hostname, dst)		
	end

	def self.edgeu_command(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		cost = msgParsed[2].to_i

		# ALWAYS update DST's cost
		$neighbors[dst][0] = cost

		# If new cost to DST is better than previous route to DST,
		# update routing table with DST as nextHop with new cost
		if ( $rt_table[dst][1] > cost )
			$rt_table[dst][0] = dst
			$rt_table[dst][1] = cost
		end

		# Update edge to dst with cost
		$graph.add_edge($hostname, dst, cost)
	end

	def self.lsu_command(threadMsg)
		# FORMAT RECIEVED: 
		# [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]
		msgParsed = threadMsg.split(" ")
		
		src = msgParsed[1]
		dst = msgParsed[2]
		cost = msgParsed[3].to_i
		seq_num = msgParsed[4].to_i
		node_sent_from = msgParsed[5]
		
		# Don't send out link state packet if it's the same node
		if ( $hostname.eql?(src) )
			return
		end

		# Don't send out link state packet if it's an older sequence number
		if ( seq_num < $sequence_num )
			return
		end

		# Send out new link state packet coming from this node
		lsu_packet = "LSU #{src} #{dst} #{cost} #{seq_num} #{$hostname}"

		# Add to received lst packets to ensure it won't send same one
		$lst_received[src] << node_sent_from

		$graph.add_edge(src, dst, cost)

		$neighbors.each do | edgeName, info |	 
			# Send message for LinkStateUpdate
			# Check whether it received this specific lst packet from
			# this neighbor
			if ( !$lst_received[src].include?(edgeName) )
				info[1].puts( lsu_packet )
			end
		end
	end
	
	# SENDMSG command.
	# Called only on original node. Any sequential nodes should either
	# use PASSTHROUGH or RECMSG
	def self.sendmsg_command(threadMsg) 
		# FORMAT:
		# SNDMSG [DST] [MSG]
		msgParsed = threadMsg.split(" ", 3)
		puts "1"
		# Destination and message to send
		dst = msgParsed[1]
		msg = msgParsed[2]
		
		# Socket to nextHop neighbor
		nextHop_socket = nil
		puts "1"
		# If the destination node in SENDMSG command
		# is NOT connected to this node, or this node itself,
		# print failure message, and return
		puts "1"
		nextHop_neighbor = $rt_table[dst][0] #change doesn't exist...
		if ( $neighbors[nextHop_neighbor] == nil ) #...doesn't exist
			if ( dst == $hostname ) #.. but if current node (sending to itself)...
				STDOUT.puts msg
			end
			puts "1"
			STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE" #...unconnected...
			return
		end
		puts "1"
		# Create a packet to fragment, 
		segment_of_message = Segment.new( $hostname, dst, message, $max_pyld )
		puts "1"
		# Get array of fragments to send from packet
		ary_of_fragments = segment_of_message.get_fragments
		puts "1"
		# If nextHop is dst, send REQUEST:RECMSG
		# else, sent PT:  (passthrough)
		ary_of_fragments.each do | fragment_to_send |
			passthrough_msg = "PT:" + fragment_to_send.to_s
			STDOUT.puts "Before sending passthrough:\n> " + passthrough_msg
			nextHop_socket.puts(passthrough_msg)
		end
	
	end
	
	# "Helper" sub message of SENDMSG command.
	# Called on nodes on the way to the destination.
	# Any sequential nodes should either
	# use PT: or RECMSG:
	def self.sendmsg_passthrough_command(threadMsg)
		
		frgmt_str = threadMsg
		
		# Convert the string representing a fragment,
		# parse its header, and return a Fragment object
		# to use to determing routing
		rec_frgmt = Segment.parse_fragment( frgmt_str )
		rec_frgmt_hdr = rec_frgmt.get_hdr
		
		dst = rec_frgmt_hdr.dst_nd
		
		# Determine if the dst is within one hop reach,
		# or will need to pass through another node.
		nextHop_neighbor = $rt_table[dst][0]
		message_to_send = nil
		
		if ( nextHop_neighbor == dst)
			message_to_send = "RECMSG:" + frgmt_str
		else
			message_to_send = "PT:" + frgmt_str
		end
		
		# Send message over socket
		if ( ( nextHop_socket = $neighbors[nextHop_neighbor][1] ) != nil )
			nextHop_socket.puts( message_to_send )
		end
		
	end
	
	# "Helper" sub message of SENDMSG command.
	# Called on nodes that recieves the message.
	# Will intake fragment, and add it to a hash
	# of started messages
	def self.sendmsg_recmsg_command(threadMsg)
	
		frgmt_str = threadMsg

		if ( ( segmentMsg = Segment.defragment( frgmt_str, $id_to_fragment ) ) != nil )
			STDOUT.puts( segmentMsg )
		end
		
	end

	while (true)
		threadMsg = nil
		
		# Check whether Queue has a message/command to process
		if ( !$commandQueue.empty? )			
			threadMsg = $commandQueue.pop
			puts threadMsg
			if ( (!threadMsg.include?"REQUEST:") && (threadMsg.include?"EDGEB") )	
				edgeb_command(threadMsg)			
			elsif (threadMsg.include?"EDGED")	
				edged_command(threadMsg)
			elsif (threadMsg.include?"EDGEU")	
				edgeu_command(threadMsg)
			elsif (threadMsg.include?"LSU")
				lsu_command(threadMsg)
			elsif (threadMsg.include?"SENDMSG")
				sendmsg_command(threadMsg)
			elsif ( (requestMatch = /^REQUEST:/.match(threadMsg) ) != nil )				
				# Push REQUEST command to be run by node
				$commandQueue.push(requestMatch.post_match)
			elsif ( (passthroughMatch = /^PT:/.match(threadMsg) ) != nil )				
				# Push PT (passthrough) command to be run by node
				sendmsg_passthrough_command(passthroughMatch.post_match)
			elsif ( (recmsgMatch = /^RECMSG:/.match(threadMsg) ) != nil )				
				# Push RECMSG: (receive message fragment) command to be run by node
				sendmsg_recmsg_command(recmsgMatch.post_match)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
