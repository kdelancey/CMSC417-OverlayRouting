def SENDMSG

	# SENDMSG command.
	# Called only on original node. Any sequential nodes should either
	# use PASSTHROUGH or RECMSG
	def SENDMSG.command(threadMsg) 
		# FORMAT:
		# SNDMSG [DST] [MSG]
		msgParsed = threadMsg.split(" ", 3)
		puts "1"
		# Destination and message to send
		dst = msgParsed[1]
		msg = msgParsed[2]
		
		# Socket to nextHop neighbor
		nextHop_socket = nil
		puts "1"
		# If the destination node in SENDMSG command
		# is NOT connected to this node, or this node itself,
		# print failure message, and return
		puts "1"
		nextHop_neighbor = $rt_table[dst][0] #change doesn't exist...
		if ( $neighbors[nextHop_neighbor] == nil ) #...doesn't exist
			if ( dst == $hostname ) #.. but if current node (sending to itself)...
				STDOUT.puts msg
			end
			puts "1"
			STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE" #...unconnected...
			return
		end
		puts "1"
		# Create a packet to fragment, 
		segment_of_message = Segment.new( $hostname, dst, message, $max_pyld )
		puts "1"
		# Get array of fragments to send from packet
		ary_of_fragments = segment_of_message.get_fragments
		puts "1"
		# If nextHop is dst, send REQUEST:RECMSG
		# else, sent PT:  (passthrough)
		ary_of_fragments.each do | fragment_to_send |
			passthrough_msg = "PT:" + fragment_to_send.to_s
			STDOUT.puts "Before sending passthrough:\n> " + passthrough_msg
			nextHop_socket.puts(passthrough_msg)
		end
	
	end
	
	# "Helper" sub message of SENDMSG command.
	# Called on nodes on the way to the destination.
	# Any sequential nodes should either
	# use PT: or RECMSG:
	def SENDMSG.passthrough_command(threadMsg)
		
		frgmt_str = threadMsg
		
		# Convert the string representing a fragment,
		# parse its header, and return a Fragment object
		# to use to determing routing
		rec_frgmt = Segment.parse_fragment( frgmt_str )
		rec_frgmt_hdr = rec_frgmt.get_hdr
		
		dst = rec_frgmt_hdr.dst_nd
		
		# Determine if the dst is within one hop reach,
		# or will need to pass through another node.
		nextHop_neighbor = $rt_table[dst][0]
		message_to_send = nil
		
		if ( nextHop_neighbor == dst)
			message_to_send = "RECMSG:" + frgmt_str
		else
			message_to_send = "PT:" + frgmt_str
		end
		
		# Send message over socket
		if ( ( nextHop_socket = $neighbors[nextHop_neighbor][1] ) != nil )
			nextHop_socket.puts( message_to_send )
		end
		
	end
	
	# "Helper" sub message of SENDMSG command.
	# Called on nodes that recieves the message.
	# Will intake fragment, and add it to a hash
	# of started messages
	def SENDMSG.recmsg_command(threadMsg)
	
		frgmt_str = threadMsg

		if ( ( segmentMsg = Segment.defragment( frgmt_str, $id_to_fragment ) ) != nil )
			STDOUT.puts( segmentMsg )
		end
		
	end
	
end