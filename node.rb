require 'socket'
require 'thread'

require './utility'
require './server'
require './packet'

$port = nil					# this node's port number
$hostname = nil				# this node's hostname

$commandQueue = Queue.new	# the queue of messages/commands to process
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
	# Hash that keeps track of open sockets on this node
	openSockets = Hash.new

	# Constantly see if there is a message to pop from queue
	while (true)
		threadMsg = nil
		
		# Check whether Queue has a message/command to process
		if ( !$commandQueue.empty? )			
			threadMsg = $commandQueue.pop
			
			# If EDGEB command is called
			if ( (!threadMsg.include? "REQUEST:") && (threadMsg.include? "EDGEB") )		
				# Format of msgParsed: [EDGEB] [SRCIP] [DSTIP] [DST]
				msgParsed = threadMsg.split(" ");

				# Check whether socket has already been opened to dst node
				if (openSockets[msgParsed[3]] == nil)
					# Open a TCPSocket with the [DSTIP] on the given
					# portNum associated with DST in nodes_map
					dstPort = $nodes_map[msgParsed[3]]

					openSockets[msgParsed[3]] = TCPSocket.open(msgParsed[2], dstPort)
					
					# Adds edge of cost 1 to this node's routing table
					$rt_table[msgParsed[3]] = [msgParsed[3], 1]
					
					# Send request to dst node to add edge to its routing
					# table. Flip recieved command to do so.
					# [DSTIP] [SRCIP] [CURRENTNODENAME]
					str_request = \
						"REQUEST:EDGEB #{msgParsed[2]} #{msgParsed[1]} #{$hostname}"
					
					openSockets[msgParsed[3]].puts(str_request)
				end

			# If recieved "REQUEST:" message, commit to the request from
			# other node
			elsif ( ( rqstMatch = /REQUEST:/.match(threadMsg) ) != nil )
				# All string after "REQUEST:"
				rqstParsed = rqstMatch.post_match
				
				#TODO Eventually discriminate between different requests.
				
				# Push command to be run by node
				$commandQueue.push(rqstParsed)
			else
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

	# Thread (Main) that takes in standard input for commands
	loop do
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
