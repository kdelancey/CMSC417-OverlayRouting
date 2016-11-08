require 'header'

<<<<<<< HEAD
class Fragment
	@hdr
	@frgmt
	
	def initialize( head, part_of_message )
		@hdr = head
		@frgmt = part_of_message
	end
	
	def to_s
		return hdr.to_s + frgmt
=======
class fragment
	attr_accessor: hdr
	attr_accessor: frgmt
	
	def initialize( head, part_of_message )
		hdr = head
		frgmt = part_of_message
>>>>>>> refs/remotes/origin/master
	end
end