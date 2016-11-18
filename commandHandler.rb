require 'socket'

require './server'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler
	# Hash that keeps track of open sockets on this node
	openSockets = Hash.new

	def self.edgeb_command(threadMsg)
		# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
		msgParsed = threadMsg.split(" ")

		# Adds edge of COST 1 to DST
		$rt_table[msgParsed[3]] = [msgParsed[3], 1]

		# Destination node's port number
		dstPort = $nodes_map[msgParsed[3]]

		# Send request to dst node to add edge to its routing
		# table. Flip recieved command to do so.
		# [DSTIP] [SRCIP] [CURRENTNODENAME]
		str_request = "REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"

		# Open a TCPSocket with the [DSTIP] on the given
		# port associated with DST in nodes_map
		openSockets[msgParsed[3]] = TCPSocket.open(msgParsed[2], dstPort)
		openSockets[msgParsed[3]].puts(str_request)
	end

	def self.edged_command(threadMsg)
		# Format of msgParsed: [EDGED] [DST]
		msgParsed = threadMsg.split(" ")

		# Removes the edge to DST
		$rt_table[msgParsed[1]] = nil
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
				puts "EDGEB command"
				edgeb_command(threadMsg)			
			elsif (threadMsg.include? "EDGED")	
				puts "EDGED command"
				edged_command(threadMsg)
			elsif (threadMsg.include? "EDGEU")	
				puts "EDGEU command"
				edgeu_command(threadMsg)
			elsif ( ( rqstMatch = /REQUEST:/.match(threadMsg) ) != nil )
				# All string after "REQUEST:"
				puts rqstMatch
				rqstParsed = rqstMatch.post_match
				
				#TODO Eventually discriminate between different requests.
				
				# Push command to be run by node
				$commandQueue.push(rqstParsed)
			else
				# do nothing for now
			end			
		end
	end
	
end
