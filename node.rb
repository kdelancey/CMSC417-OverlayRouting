require 'socket'

$port = nil
$hostname = nil
$server = nil
$listenThread = nil

# ----------------- PROJECT OBJECTS ---------------- # 

class header
	attr_accessor: hdr_sz #header size
	attr_accessor: pyld_sz #payload size
	attr_accessor: src_nd #source node
	attr_accessor: dst_nd #destination node
	attr_accessor: pkt_id #pkt id
	attr_accessor: msg_lngth #source node
	
end


# --------------------- Part 0 --------------------- # 

def edgeb(cmd)
	STDOUT.puts "EDGE: not implemented"
end

def dumptable(cmd)
	puts "DUMPTABLE: not implemented"
end

def shutdown(cmd)
	STDOUT.puts "SHUTDOWN: not implemented"
	exit(0)
end



# --------------------- Part 1 --------------------- # 
def edged(cmd)
	STDOUT.puts "EDGED: not implemented"
end

def edgew(cmd)
	STDOUT.puts "EDGEW: not implemented"
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


def listenLoop()



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

# Command Loop
#
#	Loop that reads STDIN for input, and operates
#	the given user command on this node.
def command_loop()

	while(line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		args = arr[1..-1]
		case cmd
		when "EDGEB"; edgeb(args)
		when "EDGED"; edged(args)
		when "EDGEW"; edgew(args)
		when "DUMPTABLE"; dumptable(args)
		when "SHUTDOWN"; shutdown(args)
		when "STATUS"; status()
		when "SENDMSG"; sendmsg(args)
		when "PING"; ping(args)
		when "TRACEROUTE"; traceroute(args)
		when "FTP"; ftp(args)
		else STDERR.puts "ERROR: INVALID COMMAND \"#{cmd}\""
		end
	end

end

def setup(hostname, port, nodes, config)
	$hostname = hostname
	$port = port

	server = TCPServer.new $port		

	commandThread = Thread.new do
		command_loop()
	end
	
	connectionListener = Thread.new do
		
		

end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
