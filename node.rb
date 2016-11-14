require 'socket'
require 'thread'
require './utility'
require './server'
require './packet'

$port = nil					# this node's port number
$hostname = nil				# this node's hostname

$commandQueue = Queue.new			# the queue of commands to run
$serverThread = nil			# the thread receiving incoming messages (omit?)
$connectionThread = nil		# the thread sending outgoing messages (omit?)
$nodes_map = nil			# hash of nodes to their corresponding port numbers

$config_options = nil		# array of all config options
$update_int = nil			# how often routing updates should occur (secs)
$max_pyld = nil				# the maximum size of information across one message (bytes)
$timeout = nil				# given timeout of ping (secs)

$node_time = nil 			# internal clock of this node
$rt_table = Hash.new 		# routing table of this node


# --------------------- Part 0 --------------------- # 

def edgeb(src_ip, dst_ip, dst)
	$commandQueue.push("EDGEB #{src_ip} #{dst_ip} #{dst}")
end

def dumptable(filename)
	Utility.dump_table(filename, $rt_table, $hostname)
end

def shutdown()
	STDOUT.flush
	STDERR.flush
	exit(0)
end


# --------------------- Part 1 --------------------- # 

def edged(cmd)
	STDOUT.puts "EDGED: not implemented"
end

def edgeu(cmd)
	STDOUT.puts "EDGEU: not implemented"
end

def status()
	STDOUT.puts(Utility.display_status($rt_table, $hostname, $port))
end


# --------------------- Part 2 --------------------- # 

def sendmsg(cmd)
	STDOUT.puts "SENDMSG: not implemented"
end

def ping(cmd)
	STDOUT.puts "PING: not implemented"
end

def traceroute(cmd)
	STDOUT.puts "TRACEROUTE: not implemented"
end

def ftp(cmd)
	STDOUT.puts "FTP: not implemented"
end


# --------------------- Part 3 --------------------- # 

def circuitb(cmd)
	STDOUT.puts "CIRCUITB: not implemented"
end

def circuitm(cmd)
	STDOUT.puts "CIRCUITM: not implemented"
end

def circuitd(cmd)
	STDOUT.puts "CIRCUITD: not implemented"
end


# ====================================================================
# Reads STDIN for input and operates the given user command for this
# node
# ====================================================================
def commands
	while(line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		args = arr[1..-1]
		case cmd
		when "EDGEB"; edgeb(arr[1], arr[2], arr[3])
		when "EDGED"; edged(args)
		when "EDGEU"; edgew(args)
		when "DUMPTABLE"; dumptable(arr[1])
		when "SHUTDOWN"; shutdown()
		when "STATUS"; status()
		when "SENDMSG"; sendmsg(args)
		when "PING"; ping(args)
		when "TRACEROUTE"; traceroute(args)
		when "FTP"; ftp(args)
		when "CIRCUITB"; circuitb(args)
		when "CIRCUITM"; circuitm(args)
		when "CIRCUITD"; circuitd(args)
		else STDERR.puts "ERROR: INVALID COMMAND \"#{cmd}\""
		end
	end
end

# ====================================================================
# Pops off commands from commandQueue to run them on this node
# ====================================================================
def commandHandler
	# within thread, hold hash from destination to other nodes socket
	nodeNameToSocketHash = Hash.new

	# constantly see if there is a message to pop on queue, if so...
	# either EDGEB, which will create connection, and update the table
	# within this thread, OR
	# read the destination from parsing the packet to send message

	# commandQueue has message/command to be sent out. 
	# threadMsg has message/command to be processed.
	while (true)
		threadMsg = nil
		
		if (!$commandQueue.empty?)			
			threadMsg = $commandQueue.pop

			#if message is EDGEB....
			if (threadMsg.include? "EDGEB")				
				#Format: [EDGEB] [SRCIP] [DSTIP] [DST]
				msgParsed = threadMsg.split(" ");
				
				# Adds edge of cost 1 to this node's routing table
				# TODO Update the distance when asked
				$rt_table[msgParsed[3]] = [msgParsed[3], 1]

				# If the [DST] (destination node) given in EDGEB exists 
				# in nodes_map, then it is a valid node to connect with

				# Open a TCPSocket with the [DSTIP] (dest ip) on the given
				# portNum associated with DST on nodes_map
				dstPort = $nodes_map[msgParsed[3]]
				
				if (nodeNameToSocketHash[msgParsed[3]] == nil)
					nodeNameToSocketHash[msgParsed[3]] = TCPSocket.open(msgParsed[2], dstPort)			
					
					# SEND REQUEST
					# Make new packet, that asks for a similar
					# client edge. Flip recieved command to do so.
					# [DSTIP] [SRCIP] [CURRENTNODENAME]
					str_request = \
						"REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
						
					#send in series of messages
					#rqstPacket = Packet.new $hostname,\
						#					msgParsed[3], \
							#				str_request, \
							#				$max_pyld
					
					#fragment packet, send over connection
					#rqstPacket.fragment.each { |frgmnt|
					#	nodeNameToSocketHash[msgParsed[3]].write(frgmnt.to_s)
					#}
					
					nodeNameToSocketHash[msgParsed[3]].puts(str_request)
				end

			# If recieved "REQUEST:" message, commit to the request from
			# other node
			elsif ( ( rqstMatch = /REQUEST:/.match(threadMsg) ) != nil )
			
				# All string after "REQUEST:"
				rqstParsed = rqstMatch.post_match
				
				#TODO Eventually discriminate between different requests.
				
				$commandQueue.push(rqstParsed)
			
			# elsif  ( verify it has valid header )
			else # if message is packet....
				# do nothing for now
			end			
		end
	end	
end

# ====================================================================
# Runs the node and sets up the configurations specified
# ====================================================================
def setup(hostname, port, nodes_txt, config_file)
	$hostname 		= hostname
	$port 			= port
	$nodes_map 		= Utility.read_nodes(nodes_txt)

	$config_options = Utility.read_config(config_file)
	$update_int 	= $config_options['updateInterval'].to_i
	$max_pyld 		= $config_options['maxPayload'].to_i
	$timeout 		= $config_options['pingTimeout'].to_i

	# Thread to handle server that will listen for client messages
	Thread.new {
		Server.run($port, $commandQueue)
	}	

	# Thread to handle commands that are stored in commandQueue
	Thread.new {
		commandHandler
	}

	# Main thread that takes in standard input for commands
	loop do
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
