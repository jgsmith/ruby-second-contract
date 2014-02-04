module SecondContract::Game::Systems::Resources
  ##
  # A resource is a non-negative number. Dropping to zero triggers
  # an event named "resource:$name:exhausted"
  #
  # If resource:$name:max is defined and greater than zero, then it
  # represents the maximum value to which resource:$name may be set.
  # 

  def resource name, objs = {}
    if name.end_with?(":max") && calculated?(:resource, name)
      calculate(:resource, name, objs)
    else
      get_resource(name)
    end
  end

  def get_resource name
    if resources.include?(name)
      resources[name]
    elsif name.end_with?(":max") && archetype
      archetype.get_resource(name)
    else
      0
    end
  end

  def set_resource name, val, objs = {}
    case val
    when Fixnum, Float
      if validate(:resource, name, val < 0 ? 0 : val, objs)
        if resources[name].end_with?(":max")
          resources[name] = val
        else
          resources[name] = val
          maxResource = resource(name + ":max", objs)
          if !maxResource.nil? && maxResource > 0 && resources[name] > maxResource
            resources[name] = maxResource
          elsif resources[name] < 0
            resources[name] = 0
            self.trigger_event(name + ":exhausted", objs)
          end
        end
      end
    end
  end

protected

  def initialize_resources
  end
end