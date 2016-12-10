class Edge

	def self.edgeb(threadMsg)
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
			dst_port = $nodes_map[dst]
			
			# Send request to DST to add edge to its routing
			# table. Flip recieved command to do so.
			# Format: [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = "REQUEST:EDGEB #{dst_ip} #{src_ip} #{$hostname}"
			
			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$neighbors[dst] = [1, TCPSocket.open(dst_ip, dst_port)]
			$neighbors[dst][1].puts(str_request)
		end
	end

	def self.edged(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")
		dst = msgParsed[1]

		remove_edge_packet = "EDGEREMOVE #{$hostname} #{dst}"
		$neighbors.each do | node_neighbor, neighbor_info |	
			neighbor_info[1].puts( remove_edge_packet )
		end	

		# Removes the edge between current node and DST
		# Closes socket connection between the two nodes
		$neighbors[dst][1].close
		$neighbors.delete(dst)
		
		# Remove edge from graph
		$graph.remove_edge($hostname, dst)	
	end

	def self.edgeu(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		cost = msgParsed[2].to_i

		# Update DST's cost
		$neighbors[dst][0] = cost

		# Update edge to dst with cost
		$graph.add_edge($hostname, dst, cost)
	end

	def self.edge_remove(threadMsg)
		# FORMAT of msgParsed: [EDGEREMOVE] [SRC] [DST]"
		msgParsed = threadMsg.split(" ")

		src = msgParsed[1]
		dst = msgParsed[2]
		
		$graph.remove_edge(src, dst)
	end

end
