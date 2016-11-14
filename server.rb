require 'socket'

#==========================================================
# This is our server that will be a thread that accepts
# client messages
#==========================================================
class Server

	def self.run(port, commandQueue)
		socket = TCPServer.open(port) # socket to listen on port

		while (true) do # run forever
			Thread.start(socket.accept) do |client|
				num_packets = []
				while packet = client.gets
					#puts packet
					commandQueue.push(packet)
					num_packets << packet
					sleep(10)
				end
				client.close
				# commandQueue.push(packet)
				#commandQueue.push(Packet.defragment(num_packets))
				#commandQueue.push(num_packets[0])
			end
		end
	end

end
