module SecondContract::Game::Systems::Counters
  ##
  # A trait is a number or string, typically transient and used to
  # indicate particular functionality should be enabled/disabled,
  # the state of an object, or to coordinate event handlers.
  #

  def counter name, objs = {}
    if name.end_with?(":max") && calculated?(:counter, name)
      calculate(:counter, name, objs)
    else
      get_counter(name)
    end
  end

  def get_counter name
    if counters.include?(name)
      counters[name]
    elsif name.end_with?(":max") && archetype
      archetype.get_counter(name)
    else
      0
    end
  end

  def reset_counter name, objs = {}
    counters[name] = nil
    if !%w(max debt).include?(name.split(/:/).last)
      counters[name+":debt"] = nil
    end
    if name.end_with?(':max')
      counters[name[0..-5]] = nil
      counters[name[0..-5]+":debt"] = nil
    end
  end

  def set_counter name, val, objs = {}
    case val
    when Fixnum, Float
      if val < 0
        val = 0
      end
      if validate(:counter, name, val, objs)
        if counters[name].end_with?(":max") || counters[name].end_with?(":debt")
          counters[name] = val
        else
          debt = counters[name + ":debt"]
          diff = val - counters[name]
          if diff < 0
            if debt > 0
              # if we already have debt and we decrease the counter, then we add the
              # decrease to the debt
              counters[name + ":debt"] = debt - diff
            end
            counters[name] = val
          elsif debt > diff
            counters[name + ":debt"] = debt - diff
          elsif debt > 0
            diff -= debt
            counters[name + ":debt"] = 0
            counters[name] = counters[name] + diff
          else
            counters[name] = val
          end
          maxCount = counter(name + ":max", objs)
          if counters[name] > maxCount
            val = counters[name] - maxCount
            counters[name] = maxCount
            self.trigger_event(name + ":exceeded", objs)
          end
        end
      end
    end
  end

protected

  def initialize_counters
  end
end