require 'socket'

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler

	while (true)	
		threadMsg = nil

		if ( !$commandQueue.empty? )
			threadMsg = $commandQueue.pop
			
			if ( (!threadMsg.include? "REQUEST:" ) && (threadMsg.include? "EDGEB" ) )	
				Edge.edgeb(threadMsg)			
			elsif (threadMsg.include? "EDGED" )	
				Edge.edged(threadMsg)
			elsif (threadMsg.include? "EDGEU" )	
				Edge.edgeu(threadMsg)
			elsif (threadMsg.include? "LSU" )
				LinkStateUpdate.lsu(threadMsg)
			elsif (threadMsg.include? "SENDMSG" )
				SENDMSG.command(threadMsg)
			elsif ( (requestMatch = /REQUEST:/.match(threadMsg) ) != nil )				
				$commandQueue.push(requestMatch.post_match)
			elsif ( (passthroughMatch = /^PT:/.match(threadMsg) ) != nil )				
				# Push PT (passthrough) command to be run by node
				SENDMSG.passthrough_command(passthroughMatch.post_match)
			elsif ( (recmsgMatch = /^RECMSG:/.match(threadMsg) ) != nil )				
				# Push RECMSG: (receive message fragment) command to be run by node
				SENDMSG.recmsg_command(recmsgMatch.post_match)
			elsif (threadMsg.include? "SENDPING" )
				Ping.send(threadMsg)
			elsif (threadMsg.include? "PINGERROR" )
				Ping.error(threadMsg)
			elsif (threadMsg.include? "PINGSUCCESS" )
				Ping.success(threadMsg)
			elsif (threadMsg.include? "PING" )
				Ping.ping(threadMsg)
			elsif (threadMsg.include? "TRACEROUTE" )
				Traceroute.traceroute(threadMsg)
			elsif (threadMsg.include? "SENDTR" )
				Traceroute.send(threadMsg)
			elsif (threadMsg.include? "TRERROR" )
				Traceroute.error(threadMsg)
			elsif (threadMsg.include? "TRSUCCESS" )
				Traceroute.success(threadMsg)
			elsif (threadMsg.include? "CIRCUITB")
				Circuit.build(threadMsg)	
			elsif (threadMsg.include? "CIRCUITM")
					
			elsif (threadMsg.include? "CIRCUITD")
					
			else
				STDOUT.puts "Invalid command or not implemented yet"
			end			
		end
	end
	
end
