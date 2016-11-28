require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")

		if (msgParsed.length == 4) # May not need this as commands will always be valid
		
		if ($neighbors[msgParsed[3]] == nil)
			# Adds edge of COST 1 to DST
			$rt_table[msgParsed[3]] = [msgParsed[3], 1, 0]
			
			# DST's port number
			dstPort = $nodes_map[msgParsed[3]]
			
			# Send request to DST to add edge to its routing
			# table. Flip recieved command to do so.
			# Format: [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = "REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
			
			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$neighbors[msgParsed[3]] = [1, TCPSocket.open(msgParsed[2], dstPort)]
			$neighbors[msgParsed[3]][1].puts(str_request)
		end
		
		end
	end

	def self.edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")

		if (msgParsed.length == 2) # Commands will always be valid so omit?

		# Removes the edge between current node and DST
		$neighbors.delete(msgParsed[1])
		
		#... if it was a nextHop in the routing table.
		$rt_table.each do | nodeName, routeInfo |
			
			if ( ( routeInfo[0] <=> msgParsed[1] ) == 0 ) #nextHop
				$rt_table.delete(nodeName)
			elsif ( ( nodeName <=> msgParsed[1] ) == 0 ) #the node itself
				$rt_table.delete(nodeName)
			end
			
		end
		
		end
	end

	def self.edgeu_command(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ")
		
		if (msgParsed.length == 3) # Commands will always be valid so omit?

		dst_neighbor = msgParsed[1]
		cost_to_neighbor = msgParsed[2].to_i
		
		#if valid cost
		# Omit condition? Because COST will always be a valid 32 bit integer
		# and will always be a valid command
		if (cost_to_neighbor > 0 && $neighbors.has_key?(dst_neighbor) )
			
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
	end
	
	def self.lsu_command(threadMsg)
		# FORMAT RECIEVED: 
		# [LSU] [NODE OF ORIGIN] [NODE REACHABLE] [COST OF REACH] [SEQ # WHEN REQUEST WAS SENT]
		msgParsed = threadMsg.split(" ")
		
		node_of_origin = msgParsed[1]
		node_reachable = msgParsed[2]
		cost_of_reach = msgParsed[3].to_int
		seq_num = msgParsed[4].to_int
		
		#If this message has been recieve before, return and do nothing
		if ( (sequence_to_message[seq_num] != null) and\
			 (sequence_to_message[seq_num]has_key?(node_of_origin)) and\
			 (sequence_to_message[seq_num][node_of_origin].contains(node_reachable)) )
			return
		else # else, end out message along all links (except possibly a linked neighbor who sent it)
			$neighbors.each do | edgeName, info |
				if (edgeName != node_of_origin)
					info[1].puts( threadMsg )
				end
			end
		end
		
		puts "Link State Update"
		puts $hostname
		puts msgParsed
		
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
			
			if ( $rt_table.has_key?(node_of_origin) )
				nextHop_node = $rt_table[node_of_origin][0]
				cost_of_travel_to_node_of_origin = $rt_table[node_of_origin][1]
				possible_new_cost_of_travel = \
								( cost_of_travel_to_node_of_origin + cost_of_reach )
				
				if ( $rt_table.has_key?(node_reachable) )
					prev_cost_of_travel_to_node_reachable = $rt_table[node_reachable][1]
					
					# If new cost of travel is better....
					if ( prev_cost_of_travel_to_node_reachable > possible_new_cost_of_travel )
						$rt_table[node_reachable] = [nextHop_node, \
														possible_new_cost_of_travel, \
														seq_num]
					end #else do nothing!
				
				end
				
				# If not already on the routing table, add to routing table
				$rt_table[node_reachable] = [nextHop_node, \
											 possible_new_cost_of_travel, \
													seq_num]
				
			end
			
		end
		
		
	end

	while (true)
		threadMsg = nil
		
		# Check whether Queue has a message/command to process
		if ( !$commandQueue.empty? )			
			threadMsg = $commandQueue.pop
			
			if ( (!threadMsg.include? "REQUEST:") && (threadMsg.include? "EDGEB") )	
				edgeb_command(threadMsg)			
			elsif (threadMsg.include? "EDGED")	
				edged_command(threadMsg)
			elsif (threadMsg.include? "EDGEU")	
				edgeu_command(threadMsg)
			elsif (threadMsg.include? "LSUR")	
				lsur_command(threadMsg)
			elsif (threadMsg.include? "LSU")
				puts "got here"
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
