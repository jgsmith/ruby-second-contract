module SecondContract::Game::Systems::Traits
  ##
  # A trait is a number or string, typically transient and used to
  # indicate particular functionality should be enabled/disabled,
  # the state of an object, or to coordinate event handlers.
  #

  def trait name, objs = {}
    if calculated?(:trait, name)
      ret = calculate(:trait, name, objs)
      ret
    else
      get_trait(name)
    end
  end

  def get_trait name
    if traits.include?(name)
      traits[name]
    elsif archetype
      archetype.get_trait(name)
    else
      nil
    end
  end

  def reset_trait name, objs = {}
    traits[name] = nil
  end

  def set_trait name, val
    case val
    when Fixnum, Float, String
      traits[name] = val
    else
      raise "Improper value type for trait"
    end
  end

protected

  def initialize_traits
  end
end