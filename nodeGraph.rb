class NodeGraph

    def initialize()
        @adjacency_map = Hash.new
        @distance = Hash.new
        @visited = Hash.new
        @prev = Hash.new
        @path_to_all = Hash.new
        @path_to_dst = Hash.new
        @dst_path = Array.new
    end

    # Adds symmetric edge to graph
    def self.add_edge(src, dst, cost)
        add_direct_edge(src, dst, cost)
        add_direct_edge(dst, src, cost)
    end

    # Adds directed edge from src to dst
    def self.add_direct_edge(src, dst, cost)
        if ( @adjacency_map.has_key?(src) )
            @adjacency_map[src][dst] = cost
        else
            @adjacency_map[src] = {dst => cost}
        end
    end

    # Removes symmetric edge from graph
    def self.remove_edge(src, dst)
        remove_direct_edge(src, dst)
        remove_direct_edge(dst, src)
    end

    # Removes directed edge from src to dst
    def self.remove_direct_edge(src, dst)
        @adjacency_map[src].delete(dst)
    end

    # Returns all neighbors of src vertex
    def self.get_neighbors(src)
        @adjacency_map[src]
    end

    # Returns list of all vertices in graph
    def self.get_vertices
        @adjacency_map.keys
    end

    # Returns the vertex that has the minimum distance
    def self.get_min_dist
        min_vertex = ''
        min = $INFINITY

        @visited.each do | vertex, cost |
            cost = @distance[vertex]

            if ( (!@visited[vertex]) && (cost <= min) )
                min_vertex = vertex
                min = cost
            end
        end

        min_vertex
    end

    # Runs dijkstra's algorithm on the graph to find the minimum
    # distance from src to every other vertex
    def self.dijkstra(src)

        get_vertices.each do | vertex |
            @distance[vertex] = $INFINITY
            @visited[vertex] = false
            @prev[vertex] = -1
        end

        @distance[src] = 0

        get_vertices.each do | vertex |
            min_vert = get_min_dist
            @visited[min_vert] = true

            get_neighbors(min_vert).each do | vert_neighbor, cost |
                dist_to_vertex = @distance[min_vert] + cost

                if ( dist_to_vertex < @distance[vert_neighbor] )
                    @distance[vert_neighbor] = dist_to_vertex
                    @prev[vert_neighbor] = min_vert
                end
            end
        end
    end

    # Creates path from src to dst
    def self.set_path_to_dst(src, dst)
        @dst_path = Array.new

        if ( @prev[src] != -1 )
            set_path_to_dst(@prev[src], dst)
        end

        @dst_path << src

        if ( src.eql?(dst) )
            @path_to_dst[dst] = @dst_path
        end
    end

    # Gets shortest path from source to all other nodes
    def self.src_path_to_all(src)

        get_vertices.each do | dst |
            if ( !src.eql?(dst) )
                src_path_to_dst(src, dst)
                @path_to_all[dst] = @path_to_dst[dst]
            end
        end

        @path_to_all
    end

    # Gets shortest path from src to dst
    def self.src_path_to_dst(src, dst)
        dijkstra(src)
        set_path_to_dst(dst, dst)

        @distance[dst]
    end

    # Updates routing table of graph
    def self.update_routing_table(src)
        table = Hash.new {|h,k| h[k]=[]}

        src_path_to_all(src)

        @path_to_all.keys.each do | key |
            i = 0

            if ( !key.eql?(src) )
                @path_to_all[key].each do | value |
                    if ( i < 2 )
                        table[key] << value
                        i = i + 1
                    end
                end
            end
        end

        table.keys.each do | dst |
            cost = src_path_to_dst(src, dst)

            $rt_table[dst][0] = table[dst][1]
            $rt_table[dst][1] = cost
        end
    end

end
