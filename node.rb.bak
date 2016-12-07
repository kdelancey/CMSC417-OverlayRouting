require 'socket'
require 'thread'
require 'time'

require './utility'
require './server'
require './commandHandler'
require './nodeGraph'

$port = nil					# Node's port number
$hostname = nil				# Node's hostname

$INFINITY = 2147483647		# Indicate no current path to DST

$commandQueue = Queue.new	# Queue of messages/commands to process

$nodes_map = nil			# Hash of nodes to their corresponding port numbers
$neighbors = Hash.new		# Hash of all open sockets (neighbors) to this node
							# FORMAT: [cost of nextHop, socket to nextHop]

$config_options = nil		# Array of all config options
$update_int = nil			# How often routing updates should occur (secs)
$max_pyld = nil				# Maximum size of information that can be sent (bytes)
$timeout = nil				# Given timeout of ping (secs)

$time = Time.now			# Internal clock of this node
$rt_table = Hash.new 		# Routing table of this node
							# FORMAT: [best nextHop node, cost of travel dest, latest sequence # from dst]
$sequence_num = 0			# Sequence number for link state packets
$lst_received = Hash.new 	# Keeps track of which nodes it has received link state packets from

$graph = NodeGraph.new		# Graph that represents the network with vertices and edges

#$sequence_to_message = Array.new #Holds a hash of key value pairs in the form: 
								#	hash of {seq # -> hash of {origin node -> array of[nodes reachable]} }.
								#Done to ensure that a message is not resent on a link/reused on a node.
							
# --------------------- Part 0 --------------------- # 

def edgeb(src_ip, dst_ip, dst)
	$commandQueue.push("EDGEB #{src_ip} #{dst_ip} #{dst}")
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

def edged(dst)
	$commandQueue.push("EDGED #{dst}")
end

def edgeu(dst, cost)
	$commandQueue.push("EDGEU #{dst} #{cost}")
end

def status()
	STDOUT.puts(Utility.display_status($rt_table, $hostname, $port))
end


# --------------------- Part 2 --------------------- # 

def sendmsg()
	STDOUT.puts "SENDMSG: not implemented"
end

def ping()
	STDOUT.puts "PING: not implemented"
end

def traceroute()
	STDOUT.puts "TRACEROUTE: not implemented"
end

def ftp()
	STDOUT.puts "FTP: not implemented"
end


# --------------------- Part 3 --------------------- # 

def circuitb()
	STDOUT.puts "CIRCUITB: not implemented"
end

def circuitm()
	STDOUT.puts "CIRCUITM: not implemented"
end

def circuitd()
	STDOUT.puts "CIRCUITD: not implemented"
end


# ====================================================================
# Reads STDIN for input and operates the given user command for this
# node
# ====================================================================
def commands
	while (line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		case cmd
		when "EDGEB"; edgeb(arr[1], arr[2], arr[3])
		when "EDGED"; edged(arr[1])
		when "EDGEU"; edgeu(arr[1], arr[2])
		when "DUMPTABLE"; dumptable(arr[1])
		when "SHUTDOWN"; shutdown()
		when "STATUS"; status()
		when "SENDMSG"; sendmsg()
		when "PING"; ping()
		when "TRACEROUTE"; traceroute()
		when "FTP"; ftp()
		when "CIRCUITB"; circuitb()
		when "CIRCUITM"; circuitm()
		when "CIRCUITD"; circuitd()
		else STDERR.puts "ERROR: INVALID COMMAND \"#{cmd}\""
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

	# Adds every other node to this node's routing table
	# INFINITY indicates that there is no current path to that node
	$nodes_map.each do | node_name, port |
		if ( !node_name.eql?($hostname) )
			$rt_table[node_name] = [nil, $INFINITY, 0]
		end
	end

	# Thread to handle update of the timer
	Thread.new {
		while (true) 
			sleep(0.5)
			$time = $time + 0.5
		end
	}

	# Thread to handle server that will listen for client messages
	Thread.new {
		Server.run($port)
	}	

	# Thread to handle commands that are stored in commandQueue
	Thread.new {
		commandHandler
	}
	
	# Thread to handle the creation of Link State Updates
	Thread.new {
		sequence_to_start = 1
		
		while (true)
			# Sleep until update interval time
			sleep($update_int)
			$lst_received = Hash.new {|h,k| h[k]=[]}

			packet_array = Array.new
			
			$neighbors.each do | edgeName, info |
				# FORMAT: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]
				packet_array << "LSU #{$hostname} #{edgeName} #{info[0]} #{$sequence_to_start} #{$hostname}"
			end

			$neighbors.each do | edgeName, info |	
				#send out link state packets of neighbors to each neighbor
				packet_array.each do | link_state_packet |
					#Send message for LinkStateUpdate
					info[1].puts( link_state_packet )
				end
			end

			sequence_to_start = sequence_to_start + 1
			$sequence_num = $sequence_num + 1

			$graph.update_routing_table($hostname)
		end
	}

	sleep(0.5)

	# Main thread that takes in standard input for commands
	while (true)
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
