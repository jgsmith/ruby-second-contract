module SecondContract::Game::Systems::Details 

  require 'second-contract/util/graph'

  ##
  # Details provide description of an object and its parts.
  # The 'default' detail provides the primary description of an object.
  #
  # :noun - list of nouns
  # :adjective - list of adjectives
  # :short
  # :long
  # :related-to - detail this one is related to
  # :related-by - preposition describing the relationship
  # :archetype - archetype that can be used to detach this detail from the object
  #  
  def detail key, objs = {}
    if calculated?(:detail, key)
      calculate(:detail, key, objs)
    else
      get_detail(key)
    end
  end

  def get_detail key
    # we want to collect all of the information we have about this detail
    if details.include?(key)
      details[key]
    elsif archetype
      archetype.get_detail(key)
    else
      nil
    end
  end

  def set_detail key, val, objs = {}
    if validate(:detail, key, val, objs)
      details[key] = val
    end
  end

  def get_all_detail key, objs = {}
    if archetype
      info = archetype.get_all_detail(key, objs)
    else
      info = {}
    end
    key = key + ":"
    info.merge(details.select{ |k, v|
      k.start_with?(key)
    }.inject({}) {
      |h,pair|
      h[pair.first.sub(key, '')] = pair.last
      h
    }).merge(calculate_all(:detail, key, objs)).inject({}) {
      |h,pair|
      h[pair.first.sub(/^detail:[^:]+:/, '')] = pair.last
      h
    }
  end

  ##
  # Used to build a description centered on the detail named by `coord`.
  #
  # TODO: move graph construction out so it can be built with all details
  #       and cached
  #
  def describe_detail key: 'default', sense: 'sight', seasons: [], times: [], objs: {}
    description = []
    info = get_all_detail(key, objs)
    if info
      # we want to get the right sense - based on seasons, times, and sense
      # #{sense}:#{season}:#{time}
      # #{sense}:#{season}
      # #{sense}:#{time}
      # #{sense}
      seasons.each do |season|
        times.each do |times|
          if info["#{season}:#{sense}:#{time}"]
            description << info["#{sense}:#{season}:#{time}"]
            break
          end
        end
        break if !description.empty?
      end
      if description.empty?
        seasons.each do |season|
          if info["#{season}:#{sense}"]
            description << info["#{sense}:#{season}"]
            break
          end
        end
      end
      if description.empty?
        times.each do |time|
          if info["#{sense}:#{time}"]
            description << info["#{sense}:#{time}"]
            break
          end
        end
      end
      if description.empty?
        if info[sense]
          description << info[sense]
        end
      end
      if key != 'default' && info.any? { |p| p.first.start_with?('related-to') }
        # what's the shortest distance from here to 'default'?
        # that's the one we want to select in describing the detail this one is
        # probably most noticably connected to
        #
        graph = Graph.new
        graph.add_vertex('default', {})
        _populate_graph(graph, key, info)
        path = graph.shortest_path(key, 'default')
        # add reference to last component of path
        if path.length > 1
          next_info = get_all_detail(path.last)
          prep = info.keys.select{ |k| k.start_with?('related-to:') && info[k] == path.last }.first.split(/:/).drop(1).first
          description << "It is"
          if info["related-to:#{prep}:position"]
            description << info["related-to:#{prep}:position"]
          end
          description << prep
          if next_info["article"]
            description << next_info["article"]
          end
          description << next_info["name"]+"."
        end
      end
    end
    description.join(" ").gsub(/\s+/,' ')
  end

  def detail_exits key: 'default', objs: {}
  end

  def detail_enters key: 'default', objs: {}
  end

  def detail_climbs key: 'default', objs: {}
  end

  def detail_jumps key: 'default', objs: {}
  end

protected

  def initialize_details
  end

private

  @@preposition_weights = {
    in: 1,
    worn_by: 2,
    held_by: 2,
    on: 2,
    close: 3,
    against: 3,
    under: 3,
    behind: 4,
    before: 4,
    beside: 4,
    near: 5,
    over: 5,
  }

  def _populate_graph graph, src, info
    if !graph.has_vertex?(src) && info.any? { |p| p.first.start_with?('related-to:') }
      vertices = {}
      details = {}
      info.select do |k, v| 
        k.start_with?('related-to:')
      end.group_by do |p|
        p.first.split(/:/)[1]
      end.each do |prep, prepInfo|
        targets = prepInfo.select { |p|
          p.first.end_with?(':' + prep) && p.second.is_a?(String) ||
          p.first.end_with?(':detail')
        }.map { |p| p.last }
        prepDistance = @@preposition_weights[prep.to_sym]
        if !prepDistance.nil?
          vertices = targets.inject(vertices) do |vertices, detail|
            details[detail] = get_all_detail(detail)
            weight = prepDistance
            weight -= details[detail]['notability'] if details[detail] && details[detail]['notabolity']
            if !vertices.include?(detail) || vertices[detail] > weight
              vertices[detail] = prepDistance
            end
            vertices
          end
        end
      end
      graph.add_vertex(src, vertices)
      details.each do |d, i|
        _populate_graph graph, d, i
      end
    end
  end
end