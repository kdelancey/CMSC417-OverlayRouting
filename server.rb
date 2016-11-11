require 'socket'

#==========================================================
# This is our server that will be a thread that accepts
# client messages
#==========================================================
class Server

	def self.run(port, commandQueue)
		socket = TCPServer.open(port) # socket to listen on port

		loop { # run forever
			Thread.start(socket.accept) do |client|
				num_packets = []
				while packet = client.gets
					puts packet
					num_packets << packet
				end
				client.close
				commandQueue.push(Packet.defragment(num_packets))
			end
		}
	end

end
