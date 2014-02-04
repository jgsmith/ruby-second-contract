module SecondContract::Game::Systems::Physicals
  require 'ruby-units'

  NO_MASS = Unit("0 kilogram")
  NO_VOLUME = Unit("0 liter")

  def get_environment
    raise 'get_environment not defined'
  end

	def physical key, objs = {}
    if calculated?(:physical, key)
      calculate(:physical, key, objs)
    else
      get_physical key
    end
  end

  def set_physical key, value, objs = {}
    case key
    when 'environment'
      # we don't set the environment here - this only reflects the
      # result of moving the object through other mechanisms
    when 'mass', 'mass:capacity'
      # we expect to use Unit(...)
      begin
        m = Unit(value)
        if NO_MASS.compatible?(m) && m >= NO_MASS
          physicals[key] = m
        end
      rescue
        # we do nothing by default
      end
    when 'volume', 'volume:capacity'
      begin
        v = Unit(value)
        if NO_VOLUME.compatible?(v) && v >= NO_VOLUME
          physicals[key] = v
        end
      rescue
      end
    when 'amount', 'amount:capacity'
      begin
        a = Unit(value)
        base = physical('amount:base')
        if !base.nil? && base.compatible?(a) && a >= base
          physicals[key] = a
        end
      rescue
      end
    when 'amount:base'
      begin
        base = Unit(value)
        if !base.nil?
          @physicals[key] = base
        end
      rescue
      end
    else
      if validate(:physical, key, value, objs)
        physicals[key] = value
      end
    end
  end

  def get_physical key
    # some things aren't inherited, such as environment
    case key
    when 'environment'
      # this is aimed at returning the item that contains this item
      get_environment
    when 'volume:base'
      NO_VOLUME
    when 'mass:base'
      NO_MASS
    else
      if physicals.include?(key)
        physicals[key]
      elsif archetype
        archetype.get_physical(key)
      else
        nil
      end
    end
  end

protected

  def initialize_physicals
  end
end