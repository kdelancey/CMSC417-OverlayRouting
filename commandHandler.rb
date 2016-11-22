require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")

		if ($open_sock[msgParsed[3]] == nil)
			# Adds edge of COST 1 to DST
			$rt_table[msgParsed[3]] = [msgParsed[3], 1]

			# DST's port number
			dstPort = $nodes_map[msgParsed[3]]

			# Send request to DST to add edge to its routing
			# table. Flip recieved command to do so.
			# [DSTIP] [SRCIP] [CURRENTNODENAME]
			str_request = "REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"

			# Open a TCPSocket with the [DSTIP] on the given
			# port associated with DST in nodes_map
			$open_sock[msgParsed[3]] = TCPSocket.open(msgParsed[2], dstPort)
			$open_sock[msgParsed[3]].puts(str_request)
		end
	end

	def self.edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")

		# Removes the edge to DST
		$rt_table.delete(msgParsed[1])
	end

	def self.edgeu_command(threadMsg)
		# Format of msgParsed: [EDGEU] [DST] [COST]
		msgParsed = threadMsg.split(" ")

		# Updates the cost of the edge to DST by COST
		$rt_table[msgParsed[1]] = [msgParsed[1], msgParsed[2]]
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
			elsif ( ( requestMatch = /REQUEST:/.match(threadMsg) ) != nil )
				# String after "REQUEST:"
				requestCommand = requestMatch.post_match
				
				# Push command to be run by node
				$commandQueue.push(requestCommand)
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
