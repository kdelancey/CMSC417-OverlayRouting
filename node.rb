require 'socket'
require 'utility'

$port = nil
$hostname = nil
$server = nil
$listenThread = nil

# ----------------- PROJECT OBJECTS ---------------- # 

class Header
	attr_accessor: hdr_sz 		# header size
	attr_accessor: pyld_sz 		# payload size
	attr_accessor: src_nd 		# source node
	attr_accessor: dst_nd 		# destination node
	attr_accessor: pkt_id 		# packet id
	attr_accessor: msg_lngth 	# message length
end

class Node
	attr_accessor: hostname		# name of node
	attr_accessor: port				# port number this node should listen on
	attr_accessor: nodes_map	# map of nodes and their ports
	attr_accessor: update_int	# how often routing updates occur (secs)
	attr_accessor: max_pyld		# maximum payload size for a message (bytes)
	attr_accessor: timeout 		# how long it should wait for a reply (secs)
	attr_accessor: node_time	# internal clock of node
	attr_accessor: rt_table		# routing table for this node
end


# --------------------- Part 0 --------------------- # 

def edgeb(cmd)
	STDOUT.puts "EDGE: not implemented"
end

def dumptable(cmd)
	STDOUT.puts "DUMPTABLE: not implemented"
end

def shutdown(cmd)
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


# Header Creator
#
#
#

# Packet Creator
#
#
#

# Header Parser
#
#
#

def header_parser( headerString )

end

# Packet Parser
#
#
#

# Listener Loop
#
#	Listens on the current node's port, parsing headers
#	from incoming connections, updating distance tables,
#	<more tbd>

def listenLoop()

end

# Command Loop
#
#	Loop that reads STDIN for input, and operates
#	the given user command on this node.

def commands()
	while(line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		args = arr[1..-1]
		case cmd
		when "EDGEB"; edgeb(args)
		when "EDGED"; edged(args)
		when "EDGEU"; edgew(args)
		when "DUMPTABLE"; dumptable(args)
		when "SHUTDOWN"; shutdown(args)
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

def setup(hostnm, port, nodes, config)
	hostname = Node.new
	hostname.hostname = hostnm
	hostname.port = port
	hostname.nodes_map = Utility.read_nodes(nodes)

	config_options = Utility.read_config(config)
	hostname.update_int = config_options['updateInterval'].to_i
	hostname.max_pyld = config_options['maxPayload'].to_i
	hostname.timeout = config_options['pingTimeout'].to_i

	server = TCPServer.new $port		

	loop do
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
