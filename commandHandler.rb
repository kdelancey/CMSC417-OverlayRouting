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

	def self.pingerror_command(threadMsg)
		# FORMAT of msgParsed: [PINGERROR] [SRC]
		msgParsed = threadMsg.split(" ")

		src = msgParsed[1]

		if ( $hostname.eql?(src) )
			STDOUT.puts "PING ERROR: HOST UNREACHABLE"
		else
			ping_next_hop = $rt_table[src][0]
			$neighbors[ping_next_hop][1].puts(threadMsg)
		end
	end

	def self.pingsuccess_command(threadMsg)
		# FORMAT of msgParsed: [PINGSUCCESS] [DST] [SEQ ID] [TIME SENT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		ping_seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		if ( $hostname.eql?(src) )
			round_trip_time = $time.to_f - time_sent

			if ( round_trip_time > $pingTimeout )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				STDOUT.puts "#{ping_seq_id} #{dst} #{round_trip_time}"
			end
		else
			ping_next_hop = $rt_table[src][0]
			$neighbors[ping_next_hop][1].puts(threadMsg)
		end
	end

	def self.sendping_command(threadMsg)
		# FORMAT of msgParsed: [SENDPING] [DST] [SEQ ID] [TIME SENT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		ping_seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		# If DST has been reached, send back success message
		if ( $hostname.eql?(dst) )
			ping_next_hop = $rt_table[src][0]

			ping_success_packet = "PINGSUCCESS #{dst} #{ping_seq_id} #{time_sent} #{src}"

			$neighbors[ping_next_hop][1].puts(ping_success_packet)

		# Send ping to nextHop of current node
		else
			ping_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if ( ping_next_hop == nil )
				ping_next_hop = $rt_table[src][0]
				ping_err_packet = "PINGERROR #{src}"

				$neighbors[ping_next_hop][1].puts(ping_err_packet)
			else
				$neighbors[ping_next_hop][1].puts(threadMsg)
			end
		end				
	end

	def self.ping_command(threadMsg)
		# FORMAT of msgParsed: [PING] [DST] [NUM PINGS] [DELAY]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		num_pings = msgParsed[2].to_i
		delay = msgParsed[3].to_i

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
				ping_next_hop = $rt_table[dst][0]

				# No path to get to DST
				if ( ping_next_hop == nil )
					STDOUT.puts "PING ERROR: HOST UNREACHABLE"
				else
					time_sent = $time.to_f
					ping_packet = "SENDPING #{dst} #{ping_seq_id} #{time_sent} #{$hostname}"
					$neighbors[ping_next_hop][1].puts(ping_packet)
				end

				ping_seq_id = ping_seq_id + 1
				num_pings = num_pings - 1

				sleep(delay)
			end
		end
	end

	def self.trerror_command(threadMsg)
		# FORMAT of msgParsed: [TRERROR] [HOP COUNT] [SRC]
		msgParsed = threadMsg.split(" ")

		hop_count = msgParsed[1]
		src = msgParsed[2]

		if ( $hostname.eql?(src) )
			STDOUT.puts "TIMEOUT ON #{hop_count}"
		else
			tr_next_hop = $rt_table[src][0]
			$neighbors[tr_next_hop][1].puts(threadMsg)
		end
	end

	def self.trsuccess_command(threadMsg)
		# FORMAT of msgParsed: [TRSUCCESS] [DST] [TIME TO NODE] [HOP COUNT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		time_to_node = msgParsed[2].to_f
		hop_count = msgParsed[3]
		src = msgParsed[4]

		if ( $hostname.eql?(src) )
			STDOUT.puts "#{hop_count} #{dst} #{time_to_node}"
		else
			tr_next_hop = $rt_table[src][0]
			$neighbors[tr_next_hop][1].puts(threadMsg)
		end
	end

	def self.sendtr_command(threadMsg)
		# FORMAT of msgParsed: [SENDTR] [DST] [TIME SENT] [HOP COUNT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		time_sent = msgParsed[2].to_f
		hop_count = msgParsed[3].to_i + 1
		src = msgParsed[4]

		time_to_node = $time.to_f - time_sent
		tr_next_hop = $rt_table[src][0]
		
		# Traceroute failure on this node if it takes too long
		if ( time_to_node > $pingTimeout )
			tr_err_packet = "TRERROR #{hop_count} #{src}"

			$neighbors[tr_next_hop][1].puts(tr_err_packet)
		
		# Traceroute success to this node, so send back success message
		else
			tr_success_packet = "TRSUCCESS #{dst} #{time_to_node} #{hop_count} #{src}"

			$neighbors[tr_next_hop][1].puts(tr_success_packet)

			# If not DST, continue traceroute
			if ( !$hostname.eql?(dst) )
				tr_next_hop = $rt_table[dst][0]

				# No path to get to DST
				if ( tr_next_hop == nil )
					tr_next_hop = $rt_table[src][0]
					tr_err_packet = "TRERROR #{hop_count} #{src}"

					$neighbors[tr_next_hop][1].puts(tr_err_packet)
				else
					sendtr_packet = "SENDTR #{dst} #{time_sent} #{hop_count} #{src}"
					$neighbors[tr_next_hop][1].puts(sendtr_packet)
				end
			end		
		end	 
	end

	def self.traceroute_command(threadMsg)
		# FORMAT of msgParsed: [TRACEROUTE] [DST]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		hop_count = 0

		# Source node has hop count of 0
		STDOUT.puts "#{hop_count} #{$hostname} 0.0"

		# Continue traceroute if DST isn't itself
		if ( !$hostname.eql?(dst) )
			tr_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if (tr_next_hop == nil )
				hop_count = hop_count + 1
				STDOUT.puts "TIMEOUT ON #{hop_count}"
			else
				time_sent = $time.to_f
				traceroute_packet = "SENDTR #{dst} #{time_sent} #{hop_count} #{$hostname}"
				$neighbors[tr_next_hop][1].puts(traceroute_packet)
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
			elsif (threadMsg.include?"PINGERROR")
				pingerror_command(threadMsg)
			elsif (threadMsg.include?"PINGSUCCESS")
				pingsuccess_command(threadMsg)
			elsif (threadMsg.include?"PING")
				ping_command(threadMsg)
			elsif (threadMsg.include?"TRACEROUTE")
				traceroute_command(threadMsg)
			elsif (threadMsg.include?"SENDTR")
				sendtr_command(threadMsg)
			elsif (threadMsg.include?"TRERROR")
				trerror_command(threadMsg)
			elsif (threadMsg.include?"TRSUCCESS")
				trsuccess_command(threadMsg)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
