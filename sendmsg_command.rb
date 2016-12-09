require './segment'

class SENDMSG

	# SENDMSG command.
	# Called only on original node. Any sequential nodes should either
	# use PASSTHROUGH or RECMSG
	def SENDMSG.command(threadMsg) 
		# FORMAT:
		# SNDMSG [DST] [MSG]
		msgParsed = threadMsg.split(" ", 3)
		# Destination and message to send
		dst = msgParsed[1]
		msg = msgParsed[2]
		
		# Socket to nextHop neighbor
		nextHop_socket = nil
		# If the destination node in SENDMSG command
		# is NOT connected to this node, or this node itself,
		# print failure message, and return
		nextHop_neighbor = $rt_table[dst][0] #change doesn't exist...
		if ( $neighbors[nextHop_neighbor] == nil ) #...doesn't exist
			if ( dst == $hostname ) #.. but if current node (sending to itself)...
				STDOUT.puts msg
			end
			STDOUT.puts "SENDMSG ERROR: HOST UNREACHABLE" #...unconnected...
			return
		end
		
		# If socket is open.
		if ( ( nextHop_socket = $neighbors[nextHop_neighbor][1] ) != nil )
			# Create a packet to fragment,
			segment_of_message = Segment.new( $hostname, dst, msg, $max_pyld )
			
			# Get array of fragments to send from packet
			ary_of_fragments = segment_of_message.get_fragments
			
			# If nextHop is dst, send RECMSG
			# else, sent PT:  (passthrough)
			type_to_send = nil
			if ( nextHop_neighbor == dst )
				type_to_send = "RECMSG:"
			else 
				type_to_send = "PT:"
			end
			
			ary_of_fragments.each do | fragment_to_send |
				passthrough_msg = type_to_send + fragment_to_send.to_s
				STDOUT.puts "Before sending:\n> " + passthrough_msg
				nextHop_socket.puts(passthrough_msg)
				sleep( 0.01 * $max_pyld)
			end
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
		
		# Parse raw string, turn into fragment, get header
		frgmt = Segment.parse_fragment(frgmt_str)
		
		# Get the id of the packet from the header info.
		frgmt_id = frgmt.get_hdr.pkt_id
		
		# If pkt_id already exists in id_to_fragment hash,
		# concat to existing array. Else, make new array.
		if ( $id_to_fragment[frgmt_id] == nil )
			$id_to_fragment[frgmt_id] = [frgmt]
		else 
			$id_to_fragment[frgmt_id] << frgmt
		end
		
		if ( ( segmentMsg = Segment.defragment( $id_to_fragment[frgmt_id], $id_to_fragment ) ) != nil )
			STDOUT.puts( segmentMsg )
		end
	end
	
end