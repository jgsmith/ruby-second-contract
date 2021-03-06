module SecondContract::Game::Systems::Flags
  def flag key, objs = {}
    key, inverted = check_inversion(key)
    if calculated?(:flag, key)
      ret = calculate(:flag, key, objs)
    else
      ret = get_flag key
    end
    inverted ^ !!ret
  end

  def get_flag key, objs = {}
    key, inverted = check_inversion(key)
    if flags.include?(key)
      ret = flags[key]
    elsif archetype
      ret = archetype.get_flag key, objs
    else
      ret = false
    end
    inverted ^ !!ret
  end

  def set_flag key, v, objs = {}
    key, inverted = check_inversion(key)
    if flags[key] != !!v^inverted
      trigger_event("change:flag:#{key}-any", objs.merge({ previous: flags[key], value: !!v ^ inverted }))
    end
    flags[key] = !!v ^ inverted
  end

  def reset_flag key, objs = {}
    flags[key] = false
  end

protected

  def initialize_flags
  end

  def check_inversion key
    bits = key.split(/:/)
    inverted = false
    if bits.first =~ /^not?-(.*)$/
      bits[0] = $1
      inverted = !inverted
    end
    if bits.last =~ /^not?-(.*)$/
      bits[bits.length-1] = $1
      inverted = !inverted
    end
    key = bits.join(":")
    [ key, inverted ]
  end
end