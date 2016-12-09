require 'socket'
require 'thread'
require 'time'

require './header'
require './fragment'
require './segment'
require './utility'
require './server'
require './commandHandler'
require './nodeGraph'

$port = nil					# Node's port number
$hostname = nil				# Node's hostname

$INFINITY = 2147483647		# Indicates no current path to DST

$commandQueue = Queue.new	# Queue of messages/commands to process

$nodes_map = nil			# Hash of nodes to their corresponding port numbers
$neighbors = Hash.new		# Hash of all open sockets (neighbors) to this node
							# FORMAT: [cost of nextHop, socket to nextHop]

$config_options = nil		# Array of all config options
$update_int = nil			# How often routing updates should occur (secs)
$max_pyld = nil				# Maximum size of neighbor_information that can be sent (bytes)
$pingTimeout = nil			# Given timeout of ping (secs)

$time = nil					# Internal clock of this node

$rt_table = Hash.new 		# Routing table of this node
							# FORMAT: [best nextHop node, cost of travel dest]

$sequence_num = 0			# Sequence number for link state packets
$lst_received = Hash.new 	# Keeps track of which nodes it has received link state packets from

$graph = NodeGraph.new		# Graph that represents the network with vertices and edges
							
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

def ping(dst, num_pings, delay)
	seq_id = 0

	while ( num_pings != 0 )
		$commandQueue.push("PING #{dst} #{seq_id}")
		num_pings = num_pings - 1
		seq_id = seq_id + 1
		sleep(delay)
	end
end

def traceroute(dst)
	$commandQueue.push("TRACEROUTE #{dst}")
end

def ftp()
	STDOUT.puts "FTP: not implemented"
end


# --------------------- Part 3 --------------------- # 

def circuitb(circuit_id, dst, circuit_list)
	circuit_nodes = circuit_list.split(",")
	STDOUT.puts "CIRCUITB: not implemented"
end

def circuitm(circuit_id, message)
	STDOUT.puts "CIRCUITM: not implemented"
end

def circuitd(circuit_id)
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
		when "PING"; ping(arr[1], arr[2].to_i, arr[3].to_i)
		when "TRACEROUTE"; traceroute(arr[1])
		when "FTP"; ftp()
		when "CIRCUITB"; circuitb(arr[1], arr[2], arr[3])
		when "CIRCUITM"; circuitm(arr[1], arr[2])
		when "CIRCUITD"; circuitd(arr[1])
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
	$update_int 	= $config_options['updateInterval'].to_f
	$max_pyld 		= $config_options['maxPayload'].to_f
	$pingTimeout 	= $config_options['pingTimeout'].to_f

	# Adds every other node to this node's routing table
	# INFINITY indicates that there is no current path to that node
	$nodes_map.each do | node_name, port |
		if ( !node_name.eql?($hostname) )
			$rt_table[node_name] = [nil, $INFINITY]
		end
	end

	# Thread to handle update of the timer
	Thread.new {
		$time = Time.new

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
		# Wait to start up other resources
		sleep(1)
		sequence_to_start = 1
		
		while (true)
			# Reset list of received lst packets every update interval
			$lst_received = Hash.new { | h, k | h[k] = [] }

			# Set up link state packet to be sent out
			link_state_packet = ''
			
			$neighbors.each do | node_neighbor, neighbor_info |
				# FORMAT: [LSU] [SRC] [DST] [COST] [SEQ #] [NODE SENT FROM]
				link_state_packet << "LSU #{$hostname} #{node_neighbor} #{neighbor_info[0]} #{sequence_to_start} #{$hostname}\n"
			end

			$neighbors.each do | node_neighbor, neighbor_info |	
				# Send out link state packets of neighbors to each neighbor
				neighbor_info[1].puts( link_state_packet )
			end

			# Ensures that the first set of link state packets are sent out
			if ( sequence_to_start != 1 )
				$sequence_num = $sequence_num + 1
			end

			sequence_to_start = sequence_to_start + 1

			# Sleep until update interval time
			sleep($update_int)

			# Update routing table using Dijkstra's algorithm
			$graph.update_routing_table($hostname)
		end
	}

	# Main thread that takes in standard input for commands
	while (true)
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
