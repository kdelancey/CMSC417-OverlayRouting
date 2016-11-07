require 'header'
require 'fragment'

class Packet

	@aryOfFragments = Array.new #array of all fragments
	
	@completeMessage = nil
	@packetId = rand
	
	@maxPayload  = nil #int representing the max number of bytes in a message
	@sourceNode = nil #source node
	@destNode = nil #destination node
	
	def initialize( source, destination, message, mxP )
	
		# Initialize instance variables
		@maxPayload = mxP
		@completeMessage = message
		@sourceNode = source
		@destNode = destination
		
		#call fragment_message on current packet
		fragment_message
	end
	
	# Fragments the completeMessage string into fragment(s).
	def fragment_message
	
		#General packet info
		timeToLive = 255
		packetId = rand
	
		#Fragment info
		additionalFragments = 1
		
		#Iterator info
		currentByte = 0 # current byte of fragment iterator
		
		if ( @completeMessage.length > maxPayload ) #fragment message
			
			while ( currentByte < completeMessage.length )
			
				#get part of completeMessage to send in fragment
				fragmentData = @completeMessage[currentByte,\
													currentByte + maxPayload]
				#increment the current byte by maxPayload + 1 
				currentByte = currentByte + maxPayload + 1
				#if the next fragment would be outside of originalMessage.length
				#additional bytes turns to 0, signalling no more fragments
				if ( currentByte >= @completeMessage.length )
					additionalFragments = 0
				end
				#create header for specific fragment
				fragmentHeader = \
				Header.new @sourceNode, @destNode,\
							@packetId, fragmentData.length\
							additionalFragments, aryOfFragments.length,\
								timeToLive
								
				f = Fragment.new fragmentHeader fragmentData
				@aryOfFragments.push( f )
			end
		else 
			#create header for specific fragment
			fragmentHeader = \
			Header.new @sourceNode, @destNode, \
						@packetId, @completeMessage.length,\
						0, aryOfFragments.length,\
							timeToLive
			f = Fragment.new fragmentHeader @completeMessage
			@aryOfFragments.push( f )
		end
		
		Fragment.new 
	end
	

end