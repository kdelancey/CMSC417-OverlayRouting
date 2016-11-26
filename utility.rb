class Utility

	# ====================================================================
	# Reads in configuration file for node and returns a Hash containing
	# the configuration options
	# (e.g. config[updateInterval] = 2
	#		config[maxPayload]	= 64
	#		config[pingTimeout] = 5)
	# ====================================================================
	def self.read_config(config_file)
		config = Hash.new

		File.open(config_file, 'r') do |file|
			file.each_line do |line|
				if (!line.empty?)
					key, value = line.split('=')
					key.strip!
					value.strip!
					config[key] = value
				end
			end
		end

		config
	end

	# ====================================================================
	# Reads in nodes file and returns a Hash containing each node with 
	# the corresponding port it should listen in on
	# (e.g. nodes_map[n1] = 10951
	#		nodes_map[n2] = 10952)
	# ====================================================================
	def self.read_nodes(nodes_file)
		nodes_map = Hash.new

		File.open(nodes_file, 'r') do |file|
			file.each_line do |line|
				if (!line.empty?)
					hostname, port = line.split(',')
					hostname.strip!
					port.strip!
					nodes_map[hostname] = port.to_i
				end
			end
		end

		nodes_map
	end

	# ====================================================================
	# Writes routing data to "filename", overwrites it if it already
	# exists. Only adds the nodes where an actual path can be taken.
	# It will follow this format in order of src, dst, nextHop:
	# Source,Destination,NextHop,Distance
	# (e.g. n1,n2,n2,1)
	# ====================================================================
	def self.dump_table(filename)
		routing_data = ''
		dst_array = Array.new

		$rt_table.each do | node_name, value |
			dst_array << node_name
		end

		dst_array.sort!

		dst_array.each do | dst |
			arr = $rt_table[dst]
			if ( arr[1] != $INFINITY)
				routing_data << "#{$hostname},#{dst},#{arr[0]},#{arr[1]}\n"
			end
		end

		File.open("#{filename}",'w') do |file|
			file.write(routing_data)
		end
	end

	# ====================================================================
	# Displays status info of this node following this format:
	# Name: Port: Neighbors: (lexicographical order)
	# (e.g. Name: n1 Port: 10951 Neighbors: n2,n3,n4)
	# ====================================================================
	def self.display_status(rt_table, hostname, port)
		status_info = "Name: #{hostname} Port: #{port} Neighbors: "
		nodes_neighbors = Array.new

		$neighbors.each do | node_name, array |
			nodes_neighbors << node_name
		end

		nodes_neighbors.sort!

		if (nodes_neighbors.size == 1)
			status_info << nodes_neighbors[0]
		elsif (nodes_neighbors.size > 1)
			status_info << nodes_neighbors.join(",")
		end

		status_info << "\n"
		status_info
	end

end
