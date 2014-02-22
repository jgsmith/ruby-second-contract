require 'second-contract/game/systems'
require 'second-contract/compiler/script'
require 'second-contract/machine/script'

class Archetype
  include SecondContract::Game::Systems

  attr_accessor :archetype, :physicals, :skills, :traits, :details,
                :counters, :resources, :flags,
                :calculations, :abilities, :qualities, :errors, :name

  def initialize(tree)
    initialize_systems
   
    @traits = {}
    @skills = {}
    @details = {}
    @physicals = {}
    @counters = {}
    @resources = {}
    @flags = {}

    @name = tree[:name]

    @archetype = nil
    @mixins = {}
    @calculations = {}
    @qualities = {}
    @abilities = {}
    @validators = {}
    @events = {}
    @errors = []

    compiler = SecondContract::Compiler::Script.new

    if tree[:archetype]
      @archetype = tree[:archetype]
    end

    if tree[:data]
      # set up the calculations first in case one setting depends on another
      tree[:data].each do |k, parse_tree|
        bits = k.split(/:/, 2)
        case bits.first
        when "trait", "traits"
          if parse_tree.first == :DATA
            set_trait(bits.last, parse_tree.last)
          else
            @calculations["trait:#{bits.last}"] = SecondContract::Machine::Script.new(compiler.compile(parse_tree))
          end
        when "detail", "details"
          if parse_tree.first == :DATA
            set_detail(bits.last, parse_tree.last)
          else
            @calculations["detail:#{bits.last}"] = SecondContract::Machine::Script.new(compiler.compile(parse_tree))
          end
        when "flag", "flags"
          if parse_tree.first == :DATA
            set_flag(bits.last, parse_tree.last)
          else
            @calculations["flag:#{bits.last}"] = SecondContract::Machine::Script.new(compiler.compile(parse_tree))
          end
        end
      end

      tree[:data].each do |k, parse_tree|
        bits = k.split(/:/, 2)
        case bits.first
        when "trait", "traits"
          if parse_tree.first != :DATA
            set_trait(bits.last, v = SecondContract::Machine::Script.new(compiler.compile(parse_tree)).run({}))
          end
        when "detail", "details"
          if parse_tree.first != :DATA
            set_detail(bits.last, v = SecondContract::Machine::Script.new(compiler.compile(parse_tree)).run({}))
          end
        when "flag", "flags"
          if parse_tree.first != :DATA
            set_flag(bits.last, v = SecondContract::Machine::Script.new(compiler.compile(parse_tree)).run({}))
          end
        end
      end
    end

    @calculations = compile_functions tree[:calculations]
    @validators = compile_functions tree[:validators]
    @abilities = compile_functions tree[:abilities], hash: false
    @qualities = compile_functions tree[:qualities], hash: false
    @events = compile_functions tree[:reactions], hash: false

    inherited = {
      calculations: {},
      qualities: {},
      abilities: {},
      reactions: {}
    }
    
    if tree[:traits]
      tree[:traits].each_pair do |name, trait|
        @mixins[name] = trait
        [:calculations, :qualities, :abilities].each do |type|
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
  end

  def errors?
    !@errors.empty?
  end

  def validated?(prefix, name)
    prefix = prefix.to_sym
    if @validators.include?(prefix) && @validators[prefix].include?(name)
      true
    elsif @mixins.any? { |t| t.last.validated?(prefix, name)}
      true
    elsif archetype
      archetype.validated?(prefix, name)
    else
      false
    end
  end

  def validate(prefix, name, value, objs = {})
    prefix = prefix.to_sym
    if @validators.include?(prefix) && @validators[prefix].include?(name)
      @validators[prefix][name].run(objs.merge({value: value}))
    elsif (mixin = @mixins.detect{|m| m.last.validated?(prefix, name)})
      mixin.last.validate(prefix, name, value, objs)
    elsif archetype
      archetype.validate(prefix, name, value, objs)
    else
      true
    end
  end

  def calculated?(prefix, name)
    prefix = prefix.to_sym
    if @calculations.include?(prefix) && @calculations[prefix].include?(name)
      true
    elsif @mixins.any? { |t| t.last.calculated?(prefix, name) }
      true
    elsif archetype
      archetype.calculated?(prefix, name)
    else
      false
    end
  end

  def calculate(prefix, name, objs = {})
    prefix = prefix.to_sym
    if @calculations.include?(prefix) && @calculations[prefix].include?(name)
      @calculations[prefix][name].run(objs)
    elsif (mixin = @mixins.detect{|m| m.last.calculated?(prefix, name)})
      mixin.last.calculate(prefix, name, objs)
    elsif archetype
      archetype.calculate(prefix, name, objs)
    else
      nil
    end
  end

  def calculate_all(prefix, name, objs = {})
    prefix = prefix.to_sym
    name = '' if name == ':'
    if archetype
      info = archetype.calculate_all(prefix, name, objs)
    else
      info = {}
    end
    info = @mixins.inject(info) { |info,m|
      info.merge(m.last.calculate_all(prefix, name, objs))
    }
    if @calculations.include?(prefix)
      @calculations[prefix].select { |p| p.first.start_with?(name) }.each do |k,v|
        info[k] = v.run(objs)
      end
    end
    info
  end

  def has_quality?(name)
    @qualities.include?(name) ||
    @mixins.any? {|m| m.last.has_quality?(name) } ||
    archetype && archetype.has_quality?(name)
  end

  def quality(name, objs = {})
    if @qualities.include?(name)
      @qualities[name].run(objs)
    elsif (mixin = @mixins.detect{|m| m.last.has_quality?(name)})
      mixin.last.quality(name, objs)
    elsif archetype
      archetype.quality(name, objs)
    else
      false
    end
  end

  def has_ability?(name)
    @abilities.include?(name) ||
    @mixins.any? {|m| m.last.has_ability?(name) } ||
    archetype && archetype.has_ability?(name)
  end

  def ability(name, objs = {})
    if @abilities.include?(name)
      @abilities[name].run(objs)
    elsif (mixin = @mixins.detect{|m| m.last.has_ability?(name)})
      mixin.last.ability(name, objs)
    elsif archetype
      archetype.ability(name, objs)
    else
      false
    end
  end

  def has_event_handler? evt
    if @events.include?(evt)
      true
    elsif @mixins.any? { |t| t.last.has_event_handler? evt }
      true
    elsif archetype
      archetype.has_event_handler?(evt)
    else
      false
    end
  end

  def call_event_handler evt, args, path = ""
    bits = evt.split(/\^\^/, 2)
    if bits.length > 1
      if bits.first == ""
        if archetype
          archetype.call_event_handler(bits.last, args, path+"^^")
        end
      elsif @mixins.include?(bits.first)
        @mixins[bits.first].call_event_handlers(bits.last, args, path+bits.first+"^^")
      end
    elsif @events.include?(evt)
      @events[evt].run(args, event_prefix: path)
    elsif (mixin = @mixins.detect{ |m| m.last.has_event_handler? evt })
      mixin.last.call_event_handler(evt, args, path + mixin.first + "^^")
    elsif archetype
      archetype.call_event_handler(evt, args, path)
    else
      nil
    end
  end

  def get_environment
    raise 'Archetypes do not have an environment'
  end

  def get_location
    raise 'Archetypes do not have a location'
  end

  def trigger_event evt, objs
    # we don't run events for archetypes
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