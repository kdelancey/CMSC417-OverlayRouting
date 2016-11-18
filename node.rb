require 'socket'
require 'thread'

require './utility'
require './server'
require './packet'
require './commandHandler'

$port = nil					# Node's port number
$hostname = nil				# Node's hostname

$commandQueue = Queue.new	# Queue of messages/commands to process
$nodes_map = nil			# Hash of nodes to their corresponding port numbers

$config_options = nil		# Array of all config options
$update_int = nil			# How often routing updates should occur (secs)
$max_pyld = nil				# Maximum size of information that can be sent (bytes)
$timeout = nil				# Given timeout of ping (secs)

$node_time = nil 			# Internal clock of this node
$rt_table = Hash.new 		# Routing table of this node


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
	while(line = STDIN.gets())
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

	# Thread to handle server that will listen for client messages
	Thread.new {
		Server.run($port)
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
