class Quality
  attr_accessor :traits, :skills, :calculations, :qualities, :abilities, :errors

  def initialize tree
    @calculations = {}
    @qualities = {}
    @abilities = {}
    @reactions = {}
    @validators = {}
    @mixins = {}
    @errors = []

    # check that inherited calculations, qualities, etc., aren't conflicting
    inherited = {
      calculations: {},
      qualities: {},
      abilities: {},
      reactions: {},
      validators: {}
    }

    @calculations = compile_functions tree[:calculations]
    @validators = compile_functions tree[:validators]
    @abilities = compile_functions tree[:abilities], hash: false
    @qualities = compile_functions tree[:qualities], hash: false
    @events = compile_functions tree[:reactions], hash: false

    tree[:mixins].each_pair do |name, trait|
      @mixins[name] = trait

      [:calculations, :qualities, :abilities, :validators].each do |type|
        trait.send(type).keys.each do |k|
          if inherited[type].include?(k)
            inherited[type][k] << name
          else
            inherited[type][k] = [ name ]
          end
        end
      end
    end

    [:calculations, :qualities, :abilities].each do |type|
      needs_local_definition = inherited[type].keys.select {|k|
        inherited[type][k].length > 1
      }
      available = self.send(type).keys
      needs_local_definition = needs_local_definition.reject { |k| available.include?(k) }
      if !needs_local_definition.empty?
        @errors.push "The following #{type} are ill-defined: #{needs_local_definition.sort.join(", ")}"
        needs_local_definition.each do |i|
          @errors.push "#{i} (#{type}) is defined in traits #{inherited[type][i].sort.join(", ")}"
        end
      end
    end
  end

  def has_ability?(nom)
    @abilities.include?(nom) || @mixins.any?{|t| t.last.has_ability?(nom) }
  end

  def ability(nom, objs)
    if @abilities.include?(nom)
      @abilities[nom].run(objs)
    elsif (mixin = @mixins.detect{ |t| t.last.has_ability?(nom) } )
      mixin.last.ability(nom, objs)
    else
      false
    end
  end

  def has_quality?(nom)
    @qualities.include?(nom) || @mixins.any?{|t| t.last.has_quality?(nom) }
  end

  def quality(nom, objs)
    if @qualities.include?(nom)
      @qualities[nom].run(objs)
    elsif (mixin = @mixins.detect{ |t| t.last.has_quality?(nom) } )
      mixin.last.quality(nom, objs)
    else
      false
    end
  end

  def validated?(prefix, name)
    prefix = prefix.to_sym
    @validators.include?(prefix) && @validators[prefix].include?(name) ||
    @mixins.any? { |t| t.last.validated?(prefix, name)}
  end

  def validate(prefix, name, value, objs = {})
    prefix = prefix.to_sym
    if @validators.include?(prefix) && @validators[prefix].include?(name)
      @validators[prefix][name].run(objs.merge({value: value}))
    elsif (mixin = @mixins.detect{|m| m.last.validated?(prefix, name)})
      mixin.last.validate(prefix, name, value, objs)
    else
      true
    end
  end

  def calculated?(prefix, name)
    prefix = prefix.to_sym
    @calculations.include?(prefix) && @calculations[prefix].include?(name) ||
    @mixins.any? { |t| t.last.calculated?(prefix, name) }
  end

  def calculate(prefix, name, objs = {})
    prefix = prefix.to_sym
    if @calculations.include?(prefix) && @calculations[prefix].include?(name)
      @calculations[prefix][name].run(objs)
    elsif (mixin = @mixins.detect{|m| m.last.calculated?(prefix, name)})
      mixin.last.calculate(prefix, name, objs)
    else
      nil
    end
  end

  def calculate_all(prefix, name, objs = {})
    prefix = prefix.to_sym
    name = '' if name == ':'
    info = @mixins.inject({}) { |m|
      info.merge(m.last.calculate_all(prefix, name, objs))
    }
    if @calculations.include?(prefix)
      @calculations[prefix].select { |p| p.first.start_with?(name) }.each do |k,v|
        info[k] = v.run(objs)
      end
    end
    info
  end

  def has_event_handler? evt
    @events.include?(evt) ||
    @mixins.any? { |t| t.last.has_event_handler? evt }
  end

  def call_event_handler evt, args, path = ""
    bits = evt.split(/\^\^/, 2)
    if bits.length > 1
      if @mixins.include?(bits.first)
        @mixins[bits.first].call_event_handlers(bits.last, args, path+bits.first+"^^")
      end
    elsif @events.include?(evt)
      @events[evt].run(args, event_prefix: path)
    elsif (mixin = @mixins.detect{ |m| m.last.has_event_handler? evt })
      mixin.last.call_event_handler(evt, args, path + mixin + "^^")
    else
      nil
    end
  end

  def errors?
    !@errors.empty?
  end

protected

  def compile_functions definitions, hash: true
    if definitions.is_a?(Hash)
      compiler = SecondContract::Compiler::Script.new
      definitions.keys.inject({}) { |h, k|
        if hash
          bits = k.split(/:/, 2)
          bits[0] = bits.first.to_sym
          if !h.include?(bits.first)
            h[bits.first] = {}
          end
          h[bits.first][bits.last] = SecondContract::Machine::Script.new(compiler.compile(definitions[k]))
        else
          h[k] = SecondContract::Machine::Script.new(compiler.compile(definitions[k]))
        end
        h
      }
    else
      {}
    end
  end
end