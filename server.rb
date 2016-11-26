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
					$commandQueue.push(requestMatch.post_match)
				end

				client.close
			end
		end
	end

end
