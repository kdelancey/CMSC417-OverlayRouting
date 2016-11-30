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
				
				while packet = client.gets.chomp
					#puts packet
					$commandQueue.push(packet)
				end

				client.close
			end
		end
	end

end
