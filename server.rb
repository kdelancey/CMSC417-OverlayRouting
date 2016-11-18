require 'socket'

#==========================================================
# This is our server that will be a thread that accepts
# client messages in new threads
#==========================================================
class Server

	def self.run(port, commandQueue)
		socket = TCPServer.open(port) # socket to listen on port

		while (true)
			Thread.start(socket.accept) do |client|
				puts "Client accepted"
				num_packets = []
				while packet = client.gets
					puts packet
					commandQueue.push(packet)
				end

				client.close
			end
		end
	end

end
