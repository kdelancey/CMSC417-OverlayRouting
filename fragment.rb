require 'header'

class Fragment
	@hdr
	@frgmt
	
	def initialize( head, part_of_message )
		@hdr = head
		@frgmt = part_of_message
	end
	
	def to_s
		return hdr.to_s + frgmt
	end
end