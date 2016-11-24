
class LinkState

	@dst = nil 				#destination node of this linkstate
	@sequence_number = nil	#sequence number of the LinkState update
	@src = nil 				#the nextHop neighbor
	@cost = nil				#cost to dst through src	


	def initialize( dest, cost )
		@dst = dest
		@sequence_number = 0;
		@cost = cost
	end

end