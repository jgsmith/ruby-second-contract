class SecondContract::Archetype

  def initialize
    @calculated = {}
    @handlers = {}
    @validators = {}
    @hooks = {}
    @qualities = {}
    @abilities = {}

    @traits = {}
    @resources = {}
    @skills = {}
    @details = {}

    @mixins = {}
    @ur_object = nil
  end

  def has_calculated_value?(id)
    @calculated.include?(id) || !@ur_object.nil? && @ur_object.has_calculated_value?(id)
  end

  def has_validator_for?(id)
    @validators.include?(id) || !@ur_object.nil? && @ur_object.has_validator_for?(id)
  end

  def get_trait_value(name)
    if has_calculated_value?("trait:" + name)
      calculate_value("trait:" + name)
    else
      get_internal_trait_value(name)
    end
  end

  def get_internal_trait_value(name)
    if @traits.include?(name)
      @traits[name]
    elsif !@ur_object.nil?
      @ur_object.get_internal_trait_value(name)
    end
  end

  def calculate_value(id)

  end

  def validate_value(id, value)
    if !has_validator_for?(id)
      true
    else
      false
    end
  end

  def set_trait(name, value)
    if validate_value("trait:" + name, value)
      @traits[name] = value
    end
  end

  def reset_trait(name)
    @traits.delete(name)
  end

  def get_basic_value(name)
    # for things like position, environment, etc.
  end

  def get_internal_basic_value(name)
    # we get environment from the object position/relation graph
    # we don't store environment within an object or the template
  end

  def set_basic(name, value)
    if validate_value("basic:" + name, value)
      # set value
    end
  end

  def reset_basic(name)
  end
end