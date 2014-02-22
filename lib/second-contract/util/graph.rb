##
# This is taken from 
# http://maxburstein.com/blog/introduction-to-graph-theory-finding-shortest-path/
#
# It is not covered by the license for the rest of the source code in this
# repository/project.
#
require 'priority_queue'

class Graph
    def initialize()
        @vertices = {}
    end
  
    def add_vertex(name, edges)
        @vertices[name] = edges
    end

    def has_vertex?(name)
        @vertices.include?(name)
    end

    def vertices_within(name, distance)
        @v_seen = []
        _vertices_within(name, distance).sort_by(&:last).collect(&:first)
    end

    def _vertices_within(name, distance)
        ret = []
        @vertices[name].each_pair do |v, d|
            if !@v_seen.include?(v)
                @v_seen << v
                if d <= distance
                    ret << [ v, d ]
                    ret.concat(_vertices_within(v, distance - d).collect{ |p| p[1] += d; p })
                end
            end
        end
        ret
    end

    def bidirectional!
        @vertices.keys.each do |vertex|
            @vertices[vertex].each do |edge|
                @vertices[edge.first] ||= {}
                @vertices[edge.first][vertex] ||= edge.last
            end
        end
    end
    
    def shortest_path(start, finish)
        maxint = (2**(0.size * 8 -2) -1)
        distances = {}
        previous = {}
        nodes = PriorityQueue.new
        
        @vertices.each do | vertex, value |
            if vertex == start
                distances[vertex] = 0
                nodes[vertex] = 0
            else
                distances[vertex] = maxint
                nodes[vertex] = maxint
            end
            previous[vertex] = nil
        end
        
        while nodes
            smallest = nodes.delete_min_return_key
            
            if smallest == finish
                path = []
                while previous[smallest]
                    path.push(smallest)
                    smallest = previous[smallest]
                end
                return path
            end
            
            if smallest == nil or distances[smallest] == maxint
                break            
            end
            
            @vertices[smallest].each do | neighbor, value |
                alt = distances[smallest] + @vertices[smallest][neighbor]
                if alt < distances[neighbor]
                    distances[neighbor] = alt
                    previous[neighbor] = smallest
                    nodes[neighbor] = alt
                end
            end
        end
        return distances.inspect
    end
    
    def to_s
        return @vertices.inspect
    end
end