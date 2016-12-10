class Circuit
	
	def build(threadMsg)
		# FORMAT of msgParsed: [CIRCUITB] [DST] [LIST OF NODES]
		msgParsed = threadMsg.split(" ")

		circuit_name = msgParsed[0]
		dst = msgParsed[1]
		circuit_list = msgParsed[2].split(",")
		
		if ($circuits.has_key?(circuit_name))
			return
		end
	
	end
	
	def message()
	
	end
	
	def deconstruct()
	
	end

end