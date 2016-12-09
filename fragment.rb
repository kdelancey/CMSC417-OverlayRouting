class Fragment
	@hdr
	@frgmt
	
	def initialize( head, part_of_message )
		@hdr = head
		@frgmt = part_of_message
	end
	
	def to_s
		@hdr.to_s + @frgmt
	end
	
	def get_hdr
		@hdr
	end
	
	def get_payload
		@frgmt
	end
	
end