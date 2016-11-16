# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler
	# Hash that keeps track of open sockets on this node
	openSockets = Hash.new

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
			# If recieved "REQUEST:" message, commit to the request from
			# other node
			elsif ( ( rqstMatch = /REQUEST:/.match(threadMsg) ) != nil )
				# All string after "REQUEST:"
				rqstParsed = rqstMatch.post_match
				
				#TODO Eventually discriminate between different requests.
				
				# Push command to be run by node
				$commandQueue.push(rqstParsed)
			else
				# do nothing for now
			end			
		end
	end	

	def edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ");

		# Check whether socket has already been opened to dst node
		if (openSockets[msgParsed[3]] == nil)
			# Open a TCPSocket with the [DSTIP] on the given
			# portNum associated with DST in nodes_map
			dstPort = $nodes_map[msgParsed[3]]

			openSockets[msgParsed[3]] = TCPSocket.open(msgParsed[2], dstPort)
					
			# Adds edge of cost 1 to this node's routing table
			$rt_table[msgParsed[3]] = [msgParsed[3], 1]
			
			# Send request to dst node to add edge to its routing
			# table. Flip recieved command to do so.
			# [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = \
				"REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
					
			openSockets[msgParsed[3]].puts(str_request)
		end
	end

	def edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ");
					
		# Removes the edge from the routing table by making it nil
		$rt_table[msgParsed[1]] = nil
	end

	def edgeu_command(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ");
					
		# Updates the cost of the edge to the dst node by amount cost
		$rt_table[msgParsed[1]] = [msgParsed[1], msgParsed[2]]
	end
	
end
