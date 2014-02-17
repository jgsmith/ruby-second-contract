module SecondContract::Game::Systems::Physicals
  require 'ruby-units'

  NO_MASS = Unit("0 kilogram")
  NO_VOLUME = Unit("0 liter")
  NO_GRAVITY = Unit("0 m/s^2")
  NO_LENGTH = Unit("0 meter")
  NO_DENSITY = Unit("0 kilogram/liter")

  def get_environment
    raise 'get_environment not defined'
  end

	def physical key, objs = {}
    if !%w(mass:base gravity:base volume:base length:base environment).include?(key) &&
        calculated?(:physical, key)
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
    when 'mass:base', 'volume:base', 'gravity:base', 'length:base'
      # do nothing
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
    when 'gravity'
      begin
        v = Unit(value)
        if NO_GRAVITY.compatible?(v)
          physicals[key] = v
        end
      rescue
      end
    when 'length', 'length:capacity'
      begin
        l = Unit(value)
        if NO_LENGTH.compatible?(l) && l >= NO_LENGTH
          physicals[key] = l
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
    when 'gravity:base'
      NO_GRAVITY
    when 'length:base'
      NO_LENGTH
    when 'density:base'
      NO_DENSITY
    when 'density'
      begin
        physical('mass') / physical('volume')
      rescue
        Units("0 kilogram / liter")
      end
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