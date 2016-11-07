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
	
	$node_time		= nil
	$rt_table		= nil

	Thread.new {
		socket = TCPServer.open('', port)
		loop {
			Thread.start(socket.accept) do |client|
				client.close
			end
		}
	}	

	loop do
		commands
	end
end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
