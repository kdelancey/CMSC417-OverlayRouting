require 'header'

class fragment
	attr_accessor: hdr
	attr_accessor: frgmt
	
	def initialize( head, part_of_message )
		hdr = head
		frgmt = part_of_message
	end
end