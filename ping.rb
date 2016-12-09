class Ping

	def self.error(threadMsg)
		# FORMAT of msgParsed: [PINGERROR] [SRC]
		msgParsed = threadMsg.split(" ")

		src = msgParsed[1]

		if ( $hostname.eql?(src) )
			STDOUT.puts "PING ERROR: HOST UNREACHABLE"
		else
			ping_next_hop = $rt_table[src][0]
			$neighbors[ping_next_hop][1].puts(threadMsg)
		end
	end

	def self.success(threadMsg)
		# FORMAT of msgParsed: [PINGSUCCESS] [DST] [SEQ ID] [TIME SENT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		# Receives ACK
		if ( $hostname.eql?(src) )
			round_trip_time = $time.to_f - time_sent

			if ( round_trip_time > $pingTimeout )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				STDOUT.puts "#{seq_id} #{dst} #{round_trip_time}"
			end

		# Not SRC so continue on route going back to SRC
		else
			ping_next_hop = $rt_table[src][0]
			$neighbors[ping_next_hop][1].puts(threadMsg)
		end
	end

	def self.send(threadMsg)
		# FORMAT of msgParsed: [SENDPING] [DST] [SEQ ID] [TIME SENT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		seq_id = msgParsed[2]
		time_sent = msgParsed[3].to_f
		src = msgParsed[4]

		# If DST has been reached, send back success message
		if ( $hostname.eql?(dst) )
			ping_next_hop = $rt_table[src][0]

			ping_success_packet = "PINGSUCCESS #{dst} #{seq_id} #{time_sent} #{src}"

			$neighbors[ping_next_hop][1].puts(ping_success_packet)

		# Otherwise, send ping to nextHop of current node
		else
			ping_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if ( ping_next_hop == nil )
				ping_next_hop = $rt_table[src][0]
				ping_err_packet = "PINGERROR #{src}"

				$neighbors[ping_next_hop][1].puts(ping_err_packet)
			else
				$neighbors[ping_next_hop][1].puts(threadMsg)
			end
		end				
	end

	def self.ping(threadMsg)
		# FORMAT of msgParsed: [PING] [DST] [SEQ ID]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		seq_id = msgParsed[2]

		# Ping itself
		if ( $hostname.eql?(dst) )
			STDOUT.puts "#{seq_id} #{dst} 0.0"
		else		
			ping_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if ( ping_next_hop == nil )
				STDOUT.puts "PING ERROR: HOST UNREACHABLE"
			else
				time_sent = $time.to_f
				ping_packet = "SENDPING #{dst} #{seq_id} #{time_sent} #{$hostname}"

				$neighbors[ping_next_hop][1].puts(ping_packet)
			end
		end
	end

end
