class Circuit
	
	def self.build(threadMsg)
		# FORMAT of msgParsed: [CIRCUITB] [CIRCUIT ID] [DST] [LIST OF NODES]
		msgParsed = threadMsg.split(" ")

		circuit_name = msgParsed[1]
		dst = msgParsed[2]
		circuit_list = msgParsed[3].split(",")
		
		if ($circuits.has_key?(circuit_name))
			return
		end
	
	end
	
	def self.message()
	
	end
	
	def self.deconstruct()
	
	end

end