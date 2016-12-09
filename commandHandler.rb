require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")
		src_ip = msgParsed[1]
		dst_ip = msgParsed[2]
		dst = msgParsed[3]

		# Connection hasn't been made to DST already
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
			str_request = "REQUEST:EDGEB #{dst_ip} #{src_ip} #{$hostname}"
			
			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$neighbors[dst] = [1, TCPSocket.open(dst_ip, dstPort)]
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
		cost = msgParsed[2]

		# Update DST's cost
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
		# FORMAT of LSU line: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]

		# Split up link state packets
		lsu_array = threadMsg.split("\n")

		# Check first if these link state packets needs to be sent out
		lsu_check = lsu_array[0].split(" ")
		check_src = lsu_check[2]
		check_seq_num = msgParsed[4].to_i

		# Don't send out link state packet if it's an older sequence number
		if ( check_seq_num < $sequence_num )
			return
		end

		# Don't send out link state packets if it's the same node
		if ( $hostname.eql?(check_src) )
			return
		end

		lsu_packet = ''

		lsu_array.each do | link_state_packet |

			# FORMAT of msgParsed: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]
			msgParsed = link_state_packet.split(" ")
		
			src = msgParsed[1]
			dst = msgParsed[2]
			cost = msgParsed[3].to_i
			seq_num = msgParsed[4].to_i
			node_sent_from = msgParsed[5]

			# Add edge to graph
			$graph.add_edge(src, dst, cost)		

			# Send out new link state packet coming from this node
			lsu_packet << "LSU #{src} #{dst} #{cost} #{seq_num} #{$hostname}\n"

			# Add to received lst packets to ensure it won't send same one
			$lst_received[src] << node_sent_from

			# Send out this link state update to all applicable neighbors
			$neighbors.each do | node_neighbor, neighbor_info |	 
				# Check whether it received this specific lst packet from
				# this neighbor
				if ( !$lst_received[src].include?(node_neighbor) )
					neighbor_info[1].puts( lsu_packet )
				end
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
		seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		# Receives ACK
		if ( $hostname.eql?(src) )
			round_trip_time = $time.to_f - time_sent

			if ( round_trip_time > $pingTimeout )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				STDOUT.puts "#{seq_id} #{dst} #{round_trip_time}"
			end

		# Not SRC so continue on route going back to SRC
		else
			ping_next_hop = $rt_table[src][0]
			$neighbors[ping_next_hop][1].puts(threadMsg)
		end
	end

	def self.sendping_command(threadMsg)
		# FORMAT of msgParsed: [SENDPING] [DST] [SEQ ID] [TIME SENT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		# If DST has been reached, send back success message
		if ( $hostname.eql?(dst) )
			ping_next_hop = $rt_table[src][0]

			ping_success_packet = "PINGSUCCESS #{dst} #{seq_id} #{time_sent} #{src}"

			$neighbors[ping_next_hop][1].puts(ping_success_packet)

		# Otherwise, send ping to nextHop of current node
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
		# FORMAT of msgParsed: [PING] [DST] [SEQ ID]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		seq_id = msgParsed[2]

		# Ping itself
		if ( $hostname.eql?(dst) )
			STDOUT.puts "#{seq_id} #{dst} 0.0"
		else		
			ping_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if ( ping_next_hop == nil )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				time_sent = $time.to_f
				ping_packet = "SENDPING #{dst} #{seq_id} #{time_sent} #{$hostname}"

				$neighbors[ping_next_hop][1].puts(ping_packet)
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
		time_to_node = msgParsed[2]
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
		hop_count = msgParsed[3].to_i
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
					hop_count = hop_count + 1
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

		hop_count = hop_count + 1

		# Continue traceroute if DST isn't itself
		if ( !$hostname.eql?(dst) )
			tr_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if (tr_next_hop == nil )
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

		if ( !$commandQueue.empty? )
			threadMsg = $commandQueue.pop

			if ( (!threadMsg.include? "REQUEST:" ) && (threadMsg.include? "EDGEB" ) )	
				edgeb_command(threadMsg)			
			elsif (threadMsg.include? "EDGED" )	
				edged_command(threadMsg)
			elsif (threadMsg.include? "EDGEU" )	
				edgeu_command(threadMsg)
			elsif (threadMsg.include? "LSU" )
				lsu_command(threadMsg)
			elsif (threadMsg.include? "SENDMSG" )
				sendmsg_command(threadMsg)
			elsif ( (requestMatch = /REQUEST:/.match(threadMsg) ) != nil )				
				$commandQueue.push(requestMatch.post_match)
			elsif (threadMsg.include? "SENDPING" )
				sendping_command(threadMsg)
			elsif (threadMsg.include? "PINGERROR" )
				pingerror_command(threadMsg)
			elsif (threadMsg.include? "PINGSUCCESS" )
				pingsuccess_command(threadMsg)
			elsif (threadMsg.include? "PING" )
				ping_command(threadMsg)
			elsif (threadMsg.include? "TRACEROUTE" )
				traceroute_command(threadMsg)
			elsif (threadMsg.include? "SENDTR" )
				sendtr_command(threadMsg)
			elsif (threadMsg.include? "TRERROR" )
				trerror_command(threadMsg)
			elsif (threadMsg.include? "TRSUCCESS" )
				trsuccess_command(threadMsg)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
