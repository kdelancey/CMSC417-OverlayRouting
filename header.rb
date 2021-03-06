class Header
	attr_reader :hdr_sz #header size in bytes
	attr_reader :src_nd #source node
	attr_reader :dst_nd #destination node
	attr_reader :pkt_id #packet id
	attr_reader :msg_lngth #fragment size in bytes
	attr_reader :more_frgmnts #more fragments? 0 if no, 1 if yes
	attr_reader :ordr_of_fragment #place in order of fragments
	attr_accessor :ttl #time to live
	
	# initialize creates a header object.
	# this header object will be initialized with 
	# this header object will be used in another class, packet,
	# that upon creation, will 
	def initialize(source, destination, id, message_length, additional_fragments, 
		order_fragment, time_to_live)
		
		@src_nd = source #source node
		@dst_nd = destination #destination node
		@pkt_id = id #packet id
		@msg_lngth  = message_length #payload size in bytes
		@more_frgmnts = additional_fragments #more fragments?
		@ordr_of_fragment = order_fragment #place in order of fragments
		@ttl = time_to_live #time to live
		
		length_of_header # create header size
		
	end
	
	# to_s generates a pipe '|' delimited string in the order of:
		#header size #packet size #source node #destination node #packet id
		#payload size #more fragments? #place in order of fragments #time to live
	def to_s
		#start of packet 
		#start of header
		"#{@hdr_sz}|" +\
		"#{@src_nd}|#{@dst_nd}|" +\
		"#{@pkt_id}|#{@msg_lngth}|" +\
		"#{@more_frgmnts}|#{@ordr_of_fragment}|" +\
		"#{@ttl}|" 
		#end of header 
		#start of message
	end
	
	# ______ Private Methods ______ #
	private
	
	# Get the string length of the header.
	# This method will be used to initialize the value hdr_sz, which gives
	# the total length of the header string.
	def length_of_header
		#length of header without header size
		unfn_hdr = "|#{@src_nd}|#{@dst_nd}|"\
			"#{@pkt_id}|#{@msg_lngth}|"\
			"#{@more_frgmnts}|#{@ordr_of_fragments}|"\
			"#{@ttl}|" 
			
		# if the length of unfinished header is less than or equal to 97 char long,
		# we can assume a final hdr_len <= 99, thus add two, and set hdr_sz
		if ( unfn_hdr.length <= 97 )
			@hdr_sz = unfn_hdr.length + 2
		elsif ( unfn_hdr.length <= 996 ) #JIC, if header <= 997... same deal, but 999
			@hdr_sz = unfn_hdr.length + 3
		end
	end
end