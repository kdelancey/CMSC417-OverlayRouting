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
				SENDMSG.command(threadMsg)
			elsif ( (requestMatch = /^REQUEST:/.match(threadMsg) ) != nil )				
				# Push REQUEST command to be run by node
				$commandQueue.push(requestMatch.post_match)
			elsif ( (passthroughMatch = /^PT:/.match(threadMsg) ) != nil )				
				# Push PT (passthrough) command to be run by node
				SENDMSG.passthrough_command(passthroughMatch.post_match)
			elsif ( (recmsgMatch = /^RECMSG:/.match(threadMsg) ) != nil )				
				# Push RECMSG: (receive message fragment) command to be run by node
				SENDMSG.recmsg_command(recmsgMatch.post_match)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
