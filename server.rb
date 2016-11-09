require 'socket'

#==========================================================
# This is our server that will be a thread that accepts
# client messages
#==========================================================
class Server

	def self.listen(hostname, port)
		socket = TCPServer.open(port) # socket to listen on port

		loop { # run forever
			Thread.start(socket.accept) do |client|
				num_packets = []
				while packet = client.gets
					num_packets << packet
				end
				client.close
			end
		}
	end

end