class Traceroute

	def self.error(threadMsg)
		# FORMAT of msgParsed: [TRERROR] [HOP COUNT] [SRC] [TIMEOUT]
		msgParsed = threadMsg.split(" ")

		hop_count = msgParsed[1]
		src = msgParsed[2]
		timeout = msgParsed[3].to_f

		if ( $hostname.eql?(src) )
			STDOUT.puts "#{timeout} ON #{hop_count}"
		else
			tr_next_hop = $rt_table[src][0]
			$neighbors[tr_next_hop][1].puts(threadMsg)
		end
	end

	def self.success(threadMsg)
		# FORMAT of msgParsed: [TRSUCCESS] [DST] [TIME TO NODE] [HOP COUNT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		time_to_node = msgParsed[2]
		hop_count = msgParsed[3]
		src = msgParsed[4]

		if ( $hostname.eql?(src) )
			STDOUT.puts "#{hop_count} #{dst} #{time_to_node}"
		else
			tr_next_hop = $rt_table[src][0]
			$neighbors[tr_next_hop][1].puts(threadMsg)
		end
	end

	def self.send(threadMsg)
		# FORMAT of msgParsed: [SENDTR] [DST] [TIME SENT] [HOP COUNT] [SRC]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		time_sent = msgParsed[2].to_f
		hop_count = msgParsed[3].to_i
		src = msgParsed[4]

		time_to_node = $time.to_f - time_sent
		tr_next_hop = $rt_table[src][0]
		
		# Traceroute failure on this node if it takes too long
		if ( time_to_node > $pingTimeout )
			tr_err_packet = "TRERROR #{hop_count} #{src} #{time_to_node}"

			$neighbors[tr_next_hop][1].puts(tr_err_packet)
		
		# Traceroute success to this node, so send back success message
		else
			tr_success_packet = "TRSUCCESS #{$hostname} #{time_to_node} #{hop_count} #{src}"

			$neighbors[tr_next_hop][1].puts(tr_success_packet)

			# If not DST, continue traceroute
			if ( !$hostname.eql?(dst) )
				tr_next_hop = $rt_table[dst][0]

				# No path to get to DST
				if ( tr_next_hop == nil )
					tr_next_hop = $rt_table[src][0]
					tr_err_packet = "TRERROR #{hop_count} #{src}"

					$neighbors[tr_next_hop][1].puts(tr_err_packet)
				else
					hop_count = hop_count + 1
					sendtr_packet = "SENDTR #{dst} #{time_sent} #{hop_count} #{src}"
					$neighbors[tr_next_hop][1].puts(sendtr_packet)
				end
			end		
		end	 
	end

	def self.traceroute(threadMsg)
		# FORMAT of msgParsed: [TRACEROUTE] [DST]
		msgParsed = threadMsg.split(" ")

		dst = msgParsed[1]
		hop_count = 0

		# Source node has hop count of 0
		STDOUT.puts "#{hop_count} #{$hostname} 0.0"

		hop_count = hop_count + 1

		# Continue traceroute if DST isn't itself
		if ( !$hostname.eql?(dst) )
			time_sent = $time.to_f
			tr_next_hop = $rt_table[dst][0]

			# No path to get to DST
			if (tr_next_hop == nil )
				timeout = $time.to_f - time_sent
				STDOUT.puts "#{timeout} ON #{hop_count}"
			else
				traceroute_packet = "SENDTR #{dst} #{time_sent} #{hop_count} #{$hostname}"
				$neighbors[tr_next_hop][1].puts(traceroute_packet)
			end
		end
	end

end
