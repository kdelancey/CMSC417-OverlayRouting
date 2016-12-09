require 'socket'

#==========================================================
# This is our server that will be a thread that accepts
# client messages in new threads
#==========================================================
class Server

	def self.run(port)
		socket = TCPServer.open(port) # socket to listen on port

		while (true)
			Thread.start(socket.accept) do |client|
				num_packets = Array.new

				while packet = client.gets
					if ( !packet.include? "SENDMSG" )
						$commandQueue.push(packet)
					else
						num_packets << packet
					end
				end

				client.close

				# Defragment packets here then push to commandQueue
			end
		end
	end

end
