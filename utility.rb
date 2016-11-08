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
				key, value = line.split('=')
				key.strip!
				value.strip!
				config[key] = value
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
			files.each_line do |line|
				hostname, port = line.split(',')
				hostname.strip!
				port.strip!
				nodes_map[hostname] = port.to_i
			end
		end
		nodes_map
	end

	# ====================================================================
	# Writes routing data to "filename", overwrites it if it already
	# exists
	# ====================================================================
	def self.dump_table(filename)
		routing_data = nil
		
		File.open("#{file_name}",'w') do |file|
			file.write(routing_data)
		end
	end
end