require 'socket'
require 'utility'
require 'thread'

$port = nil					# this node's port number
$hostname = nil				# this node's hostname

$connectionMsgQueue = nil	# the queue of messages to the connectionThread
$serverThread = nil			# the thread receiving incoming messages
$connectionThread = nil		# the thread sending outgoing messages
$nodes_map = nil			# hash of nodes to their corresponding port numbers

$config_options = nil		# array of all config options
$update_int = nil			# how often routing updates should occur
$max_pyld = nil				# the maximum size of information across one message
$timeout = nil				# given timeout of ping in ms

$node_time = nil 			# internal clock of this node
$rt_table = nil 			# routing table of this node

$connectionMsgQueue = Queue.new

# --------------------- Part 0 --------------------- # 

def edgeb(src_ip, dst_ip, dst)
	STDOUT.puts "EDGE: not implemented"
end

def dumptable(filename)
	Utility.dump_table(filename)
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
	STDOUT.puts "STATUS: not implemented"
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
def commands()
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
# Runs the node and sets up the configurations specified
# ====================================================================
def setup(hostname, port, nodes, config)
	$hostname 		= hostname
	$port 			= port
	$nodes_map 		= Utility.read_nodes(nodes)

	$config_options = Utility.read_config(config)
	$update_int 	= config_options['updateInterval'].to_i
	$max_pyld 		= config_options['maxPayload'].to_i
	$timeout 		= config_options['pingTimeout'].to_i
	
	$connectionMsgQueue = Queue.new

	$serverThread.new {
		#open server listening on $port
		socket = TCPServer.open( $port )
		
		#listen on port
		while (true) 
			Thread.start(socket.accept) do |client|
				client.close
			end
		end
	}	
	
	$connectionThread.new {
	
		#possibly place this elsewhere than setup, cuz it will get big
		
		#within thread, hold hash from destination to other nodes socket
		nodeNameToSocketHash = Hash.new
		
		#constantly see if there is a message to pop on queue, if so...
			#either EDGEB, which will create connection, and update the table
			#within this thread, OR
			#read the destination from parsing the packet to send message
		
		#connectionMsgQueue has message/command to be sent out. 
		#threadMsg has message/command to be processed.
		while (true)
			threadMsg = nil
			if (!connectionMsgQueue.empty?)
				threadMsg = connectionMsgQueue.pop
				
				#LATER PLACED INTO ANOTHER METHOD for cleanliness
				
				#if message is EDGEB....
				if ( threadMsg.include? "EDGEB" )
					#Format: [EDGEB] [SRCIP] [DSTIP] [DST]
					msgParsed = threadMsg.split(" ");
					
					#If the [DST] (destination node) given in EDGEB exists 
					#	in nodes_map, then it is a valid node to connect with
					
					#Open a TCPSocket with the [DSTIP] (dest ip) on the given
					#	portNum associated with DST on nodes_map
					portNum = nodes_map[msgParsed[3]]
					if ( nodes_map[msgParsed[3]] != nil )
						nodeNameToSocketHash[msgParsed[3]] = \
							TCPSocket.new msgParsed[2], portNum.to_i
					end
					
				#elsif  ( verify it has valid header ) TODO
				else #if message is packet....
				 #do nothing for now
				end
				
			end
		end
			
	}

	# Main thread that takes in standard input for commands
	loop do
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])