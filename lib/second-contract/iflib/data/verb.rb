class SecondContract::IFLib::Data::Verb
  def initialize(data)
    @verbs = data['verbs'] || []
    @help = data['help'] || ""
    @brief = data['brief'] || ""
    @see_alsos = data['see also']
    @actions = data['actions']
    @actor_reqs = to_syms(data['actor'])
    @climates = to_syms(data['climate'])
    @terrains = to_syms(data['terrain'])
    @weathers = to_syms(data['weather'])
    @seasons = to_syms(data['season'])
    @senses = to_syms(data['sense'])
    @positions = to_syms(data['position'])
    @respirations = to_syms(data['respiration'])
    @disabled = !data['published']
    @type = data['class'].to_sym
    #@cooldown = Unit(data['cooldown']) if data['cooldown']
    @args_used = []
    @args_required = []
    @adverb_constraints = {}
    @gait = -1
    if data['direct']
      @direct = to_syms(data['direct'])
      @args_used << :direct
      @args_required << :direct unless @direct.include?(:optional)
      @direct << :nothing if @direct.empty?
    end
    if data['indirect']
      @indirect = to_syms(data['indirect'])
      @args_used << :indirect
      @args_required << :indirect unless @indirect.include?(:optional)
      @indirect << :nothing if @indirect.empty?
    end
    if data['instrument']
      @instrument = to_syms(data['instrument'])
      @args_used << :instrument
      @args_required << :instrument unless @instrument.include?(:optional)
      @instrument << :nothing if @indirect.empty?
    end

    @args_used.sort!
  end

  def type
    @type
  end

  def verbs
    @verbs
  end

  def actions
    @actions
  end

  def direct_types
    @direct
  end

  def indirect_types
    @indirect
  end

  def instrument_types
    @instrument
  end

  def communication_verb?
    @type == :communication
  end

  def disabled?
    @disabled
  end

  def fits_actor_requirements?(actor)
    if !@positions.empty?
      if !@positions.include?(actor.physical('position').to_sym)
        return false
      end
    end

    if !@actor_reqs.empty?
      if !@actor_reqs.all? { |r| actor.ability(r.to_s, { this: actor }) }
        return false
      end
    end

    if !@senses.empty?
      if !senses.any? { |s| actor.ability(s.to_s, { this: actor }) }
        return false
      end
    end
    true
  end

  def fits_environment_requirements?(environment)
    true
  end

  def fits_pos_useage?(used)
    @args_required.all?{|a| used.include?(a)} && used.all?{|a| @args_used.include?(a)}
  end

private

  def to_syms(list)
    if list.nil?
      []
    else
      list.collect{ |r| r.gsub(/\s+/, '_').to_sym }
    end
  end
end
