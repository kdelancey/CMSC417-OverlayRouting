require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[3]

		if ($neighbors[dst] == nil)
			# Adds edge of COST 1 to DST
			$rt_table[dst] = [dst, 1]

			# Add edge to graph
			$graph.add_edge($hostname, dst, 1)
			
			# DST's port number
			dstPort = $nodes_map[dst]
			
			# Send request to DST to add edge to its routing
			# table. Flip recieved command to do so.
			# Format: [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = "REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
			
			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$neighbors[dst] = [1, TCPSocket.open(msgParsed[2], dstPort)]
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
		# FORMAT of msgParsed: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]
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

		# Add edge to graph
		$graph.add_edge(src, dst, cost)

		# Send out this link state update to all applicable neighbors
		$neighbors.each do | edgeName, info |	 
			# Check whether it received this specific lst packet from
			# this neighbor
			if ( !$lst_received[src].include?(edgeName) )
				info[1].puts( lsu_packet )
			end
		end
	end
	
	def self.sendmsg_command(threadMsg) 
		# FORMAT of msgParsed: [SENDMSG] [DST] [MSG]
		msgParsed = threadMsg.split(" ")
		
		dst = msgParsed[1]
		msg = msgParsed[2]
		
		# If the destination node in SENDMSG command
		# is NOT connected to this node, print failure
		# message, and return
		if ( $rt_table.keys.include? dst )
			STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE"
		end
		
		# Create a packet to fragment, 
		segment_of_message = Segment.new $hostname, dst, message, $max_pyld 
		
		# Get array of fragments to send from packet
		ary_of_fragments = segment_of_message.get_fragments
		
		# TODO: Make this loop send out messages
		# of fragments. Feeling this will take extensive
		# debugging.
		ary_of_fragments.each do | fragment_to_send |
			
		end
	
	end

	def self.sendping_command(threadMsg)
		# FORMAT of msgParsed: [SENDPING] [DST] [SEQ ID] [ACK] [TIME SENT]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		ping_seq_id = msgParsed[2]
		ping_ack = msgParsed[3]
		time_sent = msgParsed[4].to_f

		# If DST has been reached and received ACK
		if ( ($hostname.eql?(dst)) && (ping_ack == true) )
			round_trip_time = $time.to_f - time_sent
			if ( round_trip_time > $pingTimeout )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				STDOUT.puts "#{ping_seq_id} #{dst} #{round_trip_time}"
			end

		# Reached DST, but hasn't received ACK yet	
		elsif ( ($hostname.eql?(dst)) && (ping_ack == false) )
			ping_ack = true
			ping_packet = "SENDPING #{dst} #{ping_seq_id} #{ping_ack} #{time_sent}"
			$commandQueue.push(ping_packet)

		# Send ping to nextHop of current node
		else
			pingNextHop = $rt_table[dst][0]

			# No path to get to DST
			if ( pingNextHop == nil )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				$neighbors[pingNextHop][1].puts(threadMsg)
			end
		end				
	end

	def self.ping_command(threadMsg)
		# FORMAT of msgParsed: [PING] [DST] [NUM PINGS] [DELAY]
		msgParsed = threadMsg.split(" ")
		
		dst = msgParsed[1]
		num_pings = msgParsed[2].to_i
		delay = msg[3].to_i

		ping_seq_id = 0

		# Ping itself
		if ( $hostname.eql?(dst) )
			while ( num_pings > 0 )
				STDOUT.puts "#{ping_seq_id} #{dst} 0.0"

				ping_seq_id = ping_seq_id + 1
				num_pings = num_pings - 1
				
				sleep(delay)
			end
		else
			while ( num_pings > 0 )
				ping_ack = false
				pingNextHop = $rt_table[dst][0]

				# No path to get to DST
				if ( pingNextHop == nil )
					STDOUT.puts "PING ERROR: HOST UNREACHABLE"
				else
					time_sent = $time.to_f
					ping_packet = "SENDPING #{dst} #{ping_seq_id} #{ping_ack} #{time_sent}"
					$neighbors[pingNextHop][1].puts(ping_packet)
				end

				ping_seq_id = ping_seq_id + 1
				num_pings = num_pings - 1

				sleep(delay)
			end
		end
	end

	while (true)
		threadMsg = nil
		
		# Check whether Queue has a message/command to process
		if ( !$commandQueue.empty? )			
			threadMsg = $commandQueue.pop
			
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
			elsif ( (requestMatch = /REQUEST:/.match(threadMsg) ) != nil )				
				$commandQueue.push(requestMatch.post_match)
			elsif (threadMsg.include?"SENDPING")
				sendping_command(threadMsg)
			elsif (threadMsg.include?"PING")
				ping_command(threadMsg)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
