class LinkStateUpdate

	def self.lsu(threadMsg)
		# FORMAT of LSU line: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]

		# Split up link state packets
		lsu_array = threadMsg.split("\n")

		# Check first if these link state packets needs to be sent out
		lsu_check = lsu_array[0].split(" ")
		check_src = lsu_check[1]
		check_seq_num = lsu_check[4].to_i

		# In case node gets reset, have it catch up to the most recent sequence number
		if ( $sequence_num < check_seq_num )
			$sequence_num = check_seq_num
		end

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
		end

		# Send out this link state update to all applicable neighbors
		$neighbors.each do | node_neighbor, neighbor_info |	 
			# Check whether this neighbor received this set of lst packets already
			if ( !$lst_received[check_src].include?(node_neighbor) )
				neighbor_info[1].puts( lsu_packet )
			end
		end
	end

end
