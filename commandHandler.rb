require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[3]

		if (msgParsed.length == 4) # May not need this as commands will always be valid
		
		if ($neighbors[dst] == nil)
			# Adds edge of COST 1 to DST
			$rt_table[dst] = [dst, 1, 0]
			
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
	end

	def self.edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[1]

		if (msgParsed.length == 2) # Commands will always be valid so omit?

		# Removes the edge between current node and DST
		# Closes socket connection between the two nodes
		$neighbors[dst][1].close
		$neighbors.delete(dst)
		
		#... if it was a nextHop in the routing table.
		$rt_table.each do | nodeName, routeInfo |
			
			if ( ( routeInfo[0] <=> msgParsed[1] ) == 0 ) #nextHop
				routeInfo[0] = nil
				routeInfo[1] = $INFINITY
			end
			
		end
		
		end
	end

	def self.edgeu_command(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ")
		
		puts "got to edgeU"
		
		if (msgParsed.length == 3) # Commands will always be valid so omit?

		dst_neighbor = msgParsed[1]
		cost_to_neighbor = msgParsed[2].to_i
		
			#ALWAYS Update neighbors' cost
			$neighbors[dst_neighbor][0] = cost_to_neighbor
			
			# If new cost to neighbor is better than previous route to neighbor,
			# update routing table with DST as nextHop
			if ( $rt_table[dst_neighbor][1] > cost_to_neighbor)
				$rt_table[dst_neighbor][0] = dst_neighbor
			end

			# Update DST's COST
			$rt_table[dst_neighbor][1] = cost_to_neighbor	
			
		end
	end
	
	def self.lsu_command(threadMsg)
		# FORMAT RECIEVED: 
		# [LSU] [NODE OF ORIGIN] [NODE REACHABLE] [COST OF REACH] [SEQ # WHEN REQUEST WAS SENT]
		msgParsed = threadMsg.split(" ")
		
		puts "1"
		
		node_of_origin = msgParsed[1]
		node_reachable = msgParsed[2]
		cost_of_reach = msgParsed[3].to_i
		seq_num = msgParsed[4].to_i
		
		puts "2"
		
		if ( $hostname == node_of_origin )
			return
		end
		puts "2a"
		#If this message has been recieve before, return and do nothing
		if ( ($sequence_to_message[seq_num] != nil) and\
			 ($sequence_to_message[seq_num][node_of_origin] != nil) and\
			 ($sequence_to_message[seq_num][node_of_origin].contains(node_reachable)) )
			 puts "a"
			return
		else # else, end out message along all links (except possibly a linked neighbor who sent it)
			puts "b"
			$neighbors.each do | edgeName, info |
				if (edgeName != node_of_origin)
					info[1].puts( threadMsg )
				end
			end
			puts "c"
			if ($sequence_to_message[seq_num] == nil) #if new sequence number
				$sequence_to_message[seq_num] = {node_of_origin => [node_reachable]}
			elsif ($sequence_to_message[seq_num][node_of_origin] == nil) #if new node of origin
				$sequence_to_message[seq_num][node_of_origin] = [node_reachable]
			else #if new sequence number
				$sequence_to_message[seq_num][node_of_origin] << node_reachable
			end
			puts "d"
		end
		
		puts "3"
		
		if (msgParsed.length == 5) # Commands will always be valid so omit?
		
			# FORMAT:
			# [best nextHop node, cost of travel dest, latest sequence # from dst]
			#
			# Do Dikjstras
			# Check the routing table if the [NODE OF ORIGIN] is on the routing
			# table. If it is, make its nextHop the nextHop for [NODE REACHABLE],
			# and add cost of trip to [NODE OF ORIGIN] plus [COST OF REACH].
			# If the routing table is working correctly, there should be no instance
			# where the [NODE OF ORIGIN] is not on the routing table (or else how are
			# we recieving messages from it?)
			
			puts "4"
			if ( $rt_table[node_of_origin][1] != $INFINITY )
				puts "5"
				nextHop_node = $rt_table[node_of_origin][0]
				cost_of_travel_to_node_of_origin = $rt_table[node_of_origin][1]
				possible_new_cost_of_travel = \
								( cost_of_travel_to_node_of_origin + cost_of_reach )
				
				puts "6"
				puts $hostname + " " + node_reachable
				puts $hostname.eql?(node_reachable)
				
				puts "6a"
				if ( !$hostname.eql?(node_reachable) )
					
					if ($rt_table[node_reachable][1] != $INFINITY )
						
						prev_cost_of_travel_to_node_reachable = $rt_table[node_reachable][1]
						
						
						# If new cost of travel is better....
						if ( prev_cost_of_travel_to_node_reachable > possible_new_cost_of_travel )
							$rt_table[node_reachable] = [nextHop_node, \
															possible_new_cost_of_travel, \
															seq_num]
						end #else do nothing!
					
					elsif ( $rt_table[node_reachable][1] == $INFINITY )
						puts "8"
						# If not already on the routing table, add to routing table
						$rt_table[node_reachable] = [nextHop_node, \
													 possible_new_cost_of_travel, \
															seq_num]								
					end
				end
				
				#Because node of origin is on our routing table, but the reachable node is not,
				# we assume (since all nodes are added to out routing table from the nodes.txt file)
				# that the node_reachable is us. So we make the cost to our neighbor the same.
				puts "6b"
				$neighbors[node_of_origin][1] = cost_of_reach
				puts "6c"
				if ( cost_of_reach < $rt_table[node_of_origin][1])
					$rt_table[node_of_origin] = [node_of_origin, cost_of_reach, seq_num]
				end
				puts "7"
			end
			
		end
		
		
	end

	while (true)
		threadMsg = nil
		
		# Check whether Queue has a message/command to process
		if ( !$commandQueue.empty? )			
			threadMsg = $commandQueue.pop
			
			puts threadMsg
			
			if ( (!threadMsg.include?"REQUEST:") && (threadMsg.include?"EDGEB" ) )	
				edgeb_command(threadMsg)			
			elsif (threadMsg.include?"EDGED")	
				edged_command(threadMsg)
			elsif (threadMsg.include?"EDGEU")	
				edgeu_command(threadMsg)
			elsif (threadMsg.include?"LSU")
				lsu_command(threadMsg)
			elsif ( (requestMatch = /REQUEST:/.match(threadMsg) ) != nil )				
				# Push REQUEST command to be run by node
				$commandQueue.push(requestMatch.post_match)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
