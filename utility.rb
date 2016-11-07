class Utility
 
	# ====================================================================
	# Reads in configuration file for node and returns a Hash containing
	# the configuration options
	# ====================================================================
	def self.read_config(config_file)
		config = Hash.new

		File.open(config_file, 'r') do |file|
			file.each_line do |line|
				key, value = line.split('=')
				config[key] = value
			end
		end
		config
	end

	# ====================================================================
	# Reads in nodes file and returns a Hash containing each node with 
	# the corresponding port it should listen in on
	# ====================================================================
	def self.read_nodes(nodes_file)
		nodes_map = Hash.new

		File.open(nodes_file, 'r') do |file|
			files.each_line do |line|
				hostname, port = line.split(',')
				#I propose a change to an int instead of a string
				nodes_map[hostname] = port
			end
		end
		nodes_map
	end
end