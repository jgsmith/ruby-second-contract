# == Schema Information
#
# Table name: items
#
#  id             :integer          not null, primary key
#  archetype_name :string(255)      not null
#  traits         :text             default("--- {}\n")
#  skills         :text             default("--- {}\n")
#  stats          :text             default("--- {}\n")
#  details        :text             default("--- {}\n")
#  physicals      :text             default("--- {}\n")
#  counters       :text             default("--- {}\n")
#  resources      :text             default("--- {}\n")
#  flags          :text             default("--- {}\n")
#  domain_id      :integer
#  name           :string(64)
#  transient      :boolean          default(FALSE), not null
#

##
# Objects are items in the game of any type that inherit from an
# archetype. Archetypes are defined outside the database, so they
# aren't an ActiveRecord class.
#
# Objects only inherit from an archetype - any mixins/traits must be
# included in the archetype.
#
require 'second-contract/game/systems'
require 'second-contract/model/item_relationship'
require 'second-contract/model/item_detail'
require 'second-contract/iflib/data/context'

class Item < ActiveRecord::Base
  include SecondContract::Game::Systems

  attr_accessor :fail_message

  validates_presence_of :archetype_name

  serialize :skills, Hash
  serialize :traits, Hash
  serialize :details, Hash
  serialize :stats, Hash
  serialize :physicals, Hash
  serialize :counters, Hash
  serialize :resources, Hash
  serialize :flags, Hash

  has_one :character, inverse_of: :item

  belongs_to :domain

  has_many :target_relationships, class_name: "ItemRelationship", foreign_key: :source_id, inverse_of: :source
  has_many :source_relationships, class_name: "ItemRelationship", foreign_key: :target_id, inverse_of: :target

  has_many :targets, through: :target_relationships
  has_many :sources, through: :source_relationships

  attr_accessor :binder_context

  def initialize(*args)
    super
    initialize_systems
    @fail_message = ""
    @binder_context = SecondContract::IFLib::Data::Context.new
  end

  def inspect
    "#{archetype_name}##{id}"
  end

  def item
    self
  end

  def coord
    'default'
  end

  def preposition
    'in'
  end

  def archetype
    @archetype_obj ||= SecondContract::Game.instance.get_archetype(archetype_name)
    @archetype_obj
  end

  def archetype= obj
    @archetype_obj = obj
    if !obj.nil?
      write_attribute(:archetype_name, obj.name)
    else
      write_attribute(:archetype_name, nil)
    end
  end

  def validated? prefix, name
    archetype && archetype.validated?(prefix, name)
  end

  def validate prefix, name, value, objs = {}
    archetype.nil? || archetype.validate(prefix, name, value, objs)
  end

  def calculated? prefix, name
    archetype && archetype.calculated?(prefix, name)
  end

  def calculate prefix, name, objs = {}
    if archetype.nil?
      nil
    else
      if !objs[:this]
        objs[:this] = self
      end
      archetype.calculate(prefix, name, objs.merge({this: self}))
    end
  end

  def calculate_all(prefix, name, objs = {})
    prefix = prefix.to_sym
    if archetype
      info = archetype.calculate_all(prefix, name, objs)
    else
      info = {}
    end
    info
  end 

  def quality name, objs = {}
    if archetype
      objs = objs.merge({ this: self })
      archetype.quality name, objs
    else
      false
    end
  end

  def ability name, objs = {}
    if archetype
      objs = objs.merge({ this: self })
      bits = name.split(/:/)
      pos = bits.pop
      while !bits.empty?
        if archetype.has_ability?(bits.join(":") + ':' + pos)
          return archetype.ability(bits.join(":") + ':' + pos, objs)
        end
        if pos != 'any'
          if archetype.has_ability?(bits.join(":") + ':any')
            return archetype.ability(bits.join(":") + ':any', objs)
          end
        end
        bits.pop
      end
    end
    false
  end

  def related_targets(preps = nil)
    # look for any related items that have a relationship in preps
    if preps.nil? || preps.empty?
      items = target_relationships
    else
      items = target_relationships.select{ |t| preps.include?(t.preposition) }
    end
    items.collect { |t|
      if t.detail == 'default'
        t.target
      else
        ItemDetail.new(t.target, t.detail, t.preposition)
      end
    } | related_target_details(preps)
  end

  def related_sources(preps = nil)
    if preps.nil? || preps.empty?
      items = source_relationships
    else
      items = source_relationships.select{ |t| preps.include?(t.preposition) }
    end
    items.collect { |t|
      if t.detail == 'default'
        t.target
      else
        ItemDetail.new(t.target, t.detail, t.preposition)
      end
    } | related_source_details(preps)
  end

  def related_source_details(preps = nil, coord = 'default')
    prep_regex = preps.nil? ? /:related-to:[^:]+/ : /:related-to:(#{preps.map(&:to_s).join("|").gsub(/_/,'-')})/
    info = get_all_detail('', {})
    # now we want all of the items that target this detail
    detail_keys = info.keys.map { |k| k.split(/:/).first }.uniq
    detail_relations = info.keys.select { |k|
      k.match(prep_regex)
    }

    relations = detail_relations.inject([]) { |list, k|
      if info[k] == coord
        list << ItemDetail.new(self, k.split(/:/).first)
      end
      list
    }.compact

    relations
  end

  def related_target_details(preps = nil, coord = 'default')
    # look for any related items that have a relationship in preps
    # these will all be details in the item
    info = get_all_detail(coord, {})
    info.select { |k, v|
      k.start_with?('related-to:')
    }.group_by { |p|
      p.first.split(/:/)[1].to_sym
    }.select { |prep,prepInfo|
      preps.nil? || preps.empty? || preps.include?(prep)
    }.collect { |prep, prepInfo|
      prepInfo.collect {|p| ItemDetail.new(self, p.last, prep.to_s) }
    }.flatten
  end

  def get_inventory(viewer)
    items = [ self ]
    inventory = []
    while !items.empty?
      item = items.shift
      options = item.related_sources([:in, :worn_by, :held_by, :on ])
      inventory.concat(options.select{|o| o.quality('visible', {this: o, actor: viewer}) })
      items.concat(options.select{|o| o.quality('opaque', {this: o, actor: view}) })
    end
    inventory
  end

  def get_all_inventory(viewer)
    items = [ self ]
    inventory = []
    while !items.empty?
      item = items.shift
      options = item.related_sources
      inventory.concat(options.select{|o| o.quality('visible', {this: o, actor: viewer}) })
      items.concat(options.select{|o| o.quality('opaque', {this: o, actor: view}) })
    end
    inventory
  end

  ##
  # Returns the coordinates/object considered the object's local scope -- used to describe the item's position within the
  # overall scene. Generally, we want this to be the most local/shortest relationship from the item.
  #
  def get_location
    if target_relationships.count == 1
      item = target_relationships.first
    else
      item = target_relationships.sort_by {|tr| tr.read_attribute(:preposition) }.first
    end
    if item.nil?
      nil
    else
      if item.detail == 'default'
        item.target
      else
        ItemDetail.new(item.target, item.detail, item.preposition)
      end
    end
  end

  ##
  # Returns the object considered the local scene -- used to know scope of local narration and overall descriptions.
  #
  def get_environment
    # returns the object in which this item is located
    items = [ self ]
    while !items.empty?
      item = items.shift
      options = item.related_targets([:in])
      if options.empty?
        items.concat(item.related_targets)
      else
        env = options.first
        if env.is_a?(ItemDetail)
          return env.item
        else
          return env
        end
      end  
    end
  end

  def trigger_event evt, objs
    SecondContract::Game.instance.call_event(
      SecondContract::Game::Event.new(self, evt, objs.merge({this: self}))
    )
  end

  def queue_event evt, objs
    SecondContract::Game.instance.queue_event(
      SecondContract::Game::Event.new(self, evt, objs.merge({this: self}))
    )
  end

  def has_event_handler? evt
    if archetype
      if evt =~ /^(.*)-([^:-]+)$/
        pos = $2
        bits = $1.split(/:/)
      else
        bits = evt.split(/:/)
        pos = 'any'
      end
      while !bits.empty?
        if archetype.has_event_handler?(bits.join(":") + '-' + pos)
          return true
        end
        if pos != 'any'
          if archetype.has_event_handler?(bits.join(":") + '-any')
            return true
          end
        end
        bits.pop
      end
    end
    false
  end
  
  def call_event_handler evt, args
    if archetype
      if evt =~ /^(.*)-([^:-]+)$/
        pos = $2
        bits = $1.split(/:/)
      else
        bits = evt.split(/:/)
        pos = 'any'
      end
      while !bits.empty?
        if archetype.has_event_handler?(bits.join(":") + '-' + pos)
          return archetype.call_event_handler(bits.join(":") + '-' + pos, args)
        end
        if pos != 'any'
          if archetype.has_event_handler?(bits.join(":") + '-any')
            return archetype.call_event_handler(bits.join(":") + '-any', args)
          end
        end
        bits.pop
      end
    end
    nil
  end

  def build_event_set(action, args)
    # we need to do this for each item in args - including actor
    estmp = SecondContract::Game::EventSet.new
    estmp.add_guard(
      SecondContract::Game::Event.new(self, "pre-#{action}-actor", args.merge({actor: self}))
    )
    %i(direct indirect instrument).each do |set|
      if !args[set].empty?
        args[set].each do |i|
          estmp.add_guard(
            SecondContract::Game::Event.new(i, "pre-#{action}-#{set}", args.merge({actor: self}))
          )
        end
      end
    end
    estmp.add_consequent(
      SecondContract::Game::Event.new(self, action+"-actor", args.merge({actor: self}))
    )
    %i(direct indirect instrument).each do |set|
      if !args[set].empty?
        args[set].each do |i|
          estmp.add_consequent(
            SecondContract::Game::Event.new(i, "#{action}-#{set}", args.merge({actor: self}))
          )
        end
      end
    end
    estmp.add_reaction(
      SecondContract::Game::Event.new(self, "post-#{action}-actor", args.merge({actor: self}))
    )
    %i(direct indirect instrument).each do |set|
      if !args[set].empty?
        args[set].each do |i|
          estmp.add_reaction(
            SecondContract::Game::Event.new(i, "post-#{action}-#{set}", args.merge({actor: self}))
          )
        end
      end
    end
    estmp
  end

  def build_event_sequence(actions, args)
    es = nil
    actions.each do |action|
      e = build_event_set(action, args)
      if es.nil?
        es = e
      else
        es.set_next_set(e)
      end
    end
    es
  end

  ###
  ### Parser support - only in items
  ###
  def parse_command_id_list
    ids = detail('default:noun', {this: self}) || []
    ids << detail('default:name')
    ids.compact.uniq
  end

  # TODO: make pluralize a static method or a method on String
  #
  def parse_command_plural_id_list
    parse_command_id_list.map {|id|
      SecondContract::IFLib::Sys::English.instance.pluralize(id)
    }
  end

  def parse_command_adjective_id_list
    detail('default:adjective', {this: self})
  end

  def parse_command_plural_adjective_id_list
    parse_command_adjective_id_list
  end

  def parse_match_object(input, actor, context)
    ret = is_matching_object(input, actor, context)
    if ret.empty?
      [ :no_match, [] ]
    elsif !self.quality("continuous") && !self.quality("money")
      if !context.update_number(1, ret)
        nil
      else
        [ ret, [ self ] ]
      end
    else
      # handle continuous and money
      [ :no_match, [] ]
    end
  end

  def is_matching_object(input, actor, context)
    objs = { this: self, actor: actor }
    last_bit = input[:nominal]
    ret = []
    case last_bit
    when "him"
      if self == context.him
        ret << :singular
      end
    when "her"
      if self == context.her
        ret << :singular
      end
    when "it"
      if self == context.it
        ret << :singular
      end
    when "them"
      if self.quality("plural", objs) && context.plural_objects.include?(self)
        ret << :match_plural
      end
    when "me"
      if self == actor
        ret << :singular
      end
    when "all", "things", "ones"
      if self.quality("matching-all", objs) 
        ret << :match_plural
      end
    when "thing", "one"
      if !self.quality("matching-all", objs)
        ret << :singular
      end
    end

    env = self.physical("environment", objs)
    if ret.empty?
      if last_bit == "here" && actor != env && input.length > 1
        last_bit = input.last
        input.pop
      end
      if parse_command_id_list.include?(last_bit)
        ret << :singular
      elsif parse_command_plural_id_list.include?(last_bit)
        ret << :match_plural
      end
    end

    # now match adjectives
    if !ret.empty? && input.length > 0
      adj = self.parse_command_adjective_id_list
      padj = self.parse_command_plural_adjective_id_list
      if env == actor.physical("environment")
        adj |= [ "here" ]
        padj |= [ "here" ]
      end
      if env == context.him
        adj |= [ "his" ]
      end
      if env == context.her
        adj |= [ "her" ]
      end
      if env == context.it
        adj |= [ "its" ]
      end
      if env == actor
        adj |= [ "my" ]
      end
      if context.is_plural? && context.plural_objects.include?(env)
        adj |= [ "their" ]
      end

      if !input[:adjectives].all? { |a| adj.include?(a) }
        if !input[:adjectives].all? { |a| padj.include?(a) }
          return []
        else
          ret -= [ :singular ]
          ret |= [ :match_plural ]
        end
      end
    end

    ret
  end

#
# By time this is called, we'll already have checked for guards and blocks.
# Guards and blocks are assigned to exits, not destinations.
#
# Triggers the following events:
#   pre-move:release
#   pre-move:receive
#   pre-move:accept
#
#   post-move:release
#   post-move:receive
#   post-move:accept
#
#   as appropriate (if not changing overall environment):
#     motion:in-scene
#     motion:on-path
#     motion:on-terrain
#
# pre-* events may return FALSE to block the move.
# post-* and motion:* events should provide appropriate narration.
#
# N.B.: These are only called when this object is changing environments,
# not when moving within a scene, on the same path, or in the same terrain.
#
  def do_move_to_location(klass, target_loc, msg_out = nil, msg_in = nil)
    do_move(klass, target_loc.preposition || 'in', target_loc.item, target_loc.coord, msg_out, msg_in)
  end

  def do_move(klass, target_prep, target_item, target_coord, msg_out = nil, msg_in = nil)
    config = SecondContract::Game.instance.config
    if config['messages'] && config['messages']['movement'] && config['messages']['movement'][klass]
      if msg_out.nil?
        msg_out = config['messages']['movement'][klass]['out']
      end
      if msg_in.nil?
        msg_in = config['messages']['movement'][klass]['in']
      end
    end
    # where is this item now?

    loc = get_location

    if loc.present?
      loc_item = loc.item
      loc_prep = loc.preposition
      loc_coord = loc.coord
    end

    if loc_item.present? && !loc_item.ability("move:release:#{klass}", {this: loc_item, actor: self})
      return false
    end

    if target_item.present? && !target_item.ability("move:receive:#{klass}", {this: target_item, actor: self})
      return false
    end

    if !ability("move:accept:#{klass}", {this: self})
      return false
    end

    if loc.present? && !loc_item.trigger_event("pre-move:release:#{klass}", {this: loc_item, coord: loc_coord, relation: loc_prep, actor: self })
      return false
    end

    if target_item.present? && !target_item.trigger_event("pre-move:receive:#{klass}", {this: target_item, coord: target_coord, relation: target_prep, actor: self })
      return false
    end

    if !trigger_event("pre-move:accept:#{klass}", {this: self, dest: target_item, coord: target_coord, relation: target_prep })
      return false
    end

    # now disconnect from everything in this scene that is connected to us but not part of our inventory
    if loc_item.present?
      source_relationships.reject{ |t| [:in, :worn_by, :held_by, :on].include?(t.preposition) }.each do |r|
        r.target = loc_item
        r.preposition = loc_prep.to_sym
        case loc_coord
        when String
          r.detail = loc_coord
          r.x = nil
          r.y = nil
        when Fixnum
          r.detail = nil
          r.x = loc_coord
          r.y = nil
        when Array
          r.detail = nil
          r.x = loc_coord.first
          r.y = loc_coord.last
        end
        r.save
        r.source.reload
      end
      self.reload
      loc_item.reload
    end

    # now make the connection to the new scene
    target_relationships.clear
    self.reload
    if target_item.present?
      r = target_relationships.build({
        target: target_item,
        preposition: target_prep.to_sym
      })
      case target_coord
      when String
        r.detail = target_coord
      when Fixnum
        r.x = target_coord
      when Array
        r.x = target_coord.first
        r.y = target_coord.last
      end
      r.save!
      self.reload
      target_item.reload
    end

    if loc_item.present?
      loc_item.trigger_event("post-move:release:#{klass}", {this: loc_item, coord: loc_coord, relation: loc_prep, actor: self, msg: msg_out})
    end

    trigger_event("post-move:accept:#{klass}", {this: self, dest: target_item, coord: target_coord, relation: target_prep })

    if target_item.present?
      target_item.trigger_event("post-move:receive:#{klass}", {this: target_item, coord: target_coord, relation: target_prep, actor: self, msg: msg_in })
    end

    true
  end

  def is_visible_to(actor)
    true
  end

  ###
  ### scripting support
  ###

  def driver
    SecondContract::Game::instance.term_for_item(self.id)
  end

  def script_Emit2 machine, objs
    # klass, text
    text, klass = machine.pop 2
    d = driver
    if !d.nil?
      driver.emit(klass, text)
    end
  end

  def script_Keys1 machine, objs
    ob = machine.pop 1
    if ob.nil?
      []
    elsif ob.is_a?(Array)
      ob.inject({}) { |h, m| h.merge(m) }.keys.flatten
    else
      ob.keys.flatten
    end
  end

  def script_First1 machine, objs
    ob = machine.pop 1
    Array(ob).first
  end

  def script_Rest1 machine, objs
    ob = machine.pop 1
    Array(ob).drop(1)
  end

  def script_Last1 machine, objs
    ob = machine.pop 1
    Array(ob).last
  end

  def script_ItemList1 machine, objs
    list = machine.pop 1
    SecondContract::IFLib::Sys::English.instance.item_list(list.flatten)
  end

  def script_Pluralize1 machine, objs
    SecondContract::IFLib::Sys::English.instance.pluralize(machine.pop(1))
  end

  def script_Consolidate2 machine, objs
    SecondContract::IFLib::Sys::English.instance.consolidate(*(machine.pop(2)))
  end

  def script_MoveTo2 machine, objs
    dest, klass = machine.pop 2
    dest = Array(dest).first
    case dest
    when Item
      do_move(klass, 'in', item, 'default')
    when ItemDetail
      do_move_to_location(klass, dest)
    else
      false
    end
  end

  def script_MoveTo3 machine, objs
    dest, prep, klass = machine.pop 3
    dest = Array(dest).first
    case dest
    when Item
      # move to being _prep_ Item _default_
      do_move(klass, prep, dest, 'default')
    when ItemDetail
      # move to being in the relationship described by ItemDetail
      do_move(klass, prep, dest.item, dest.coord)
    else
      # we don't move
      false
    end
  end

  def script_MoveTo4 machine, objs
    msg_in, msg_out, dest, klass = machine.pop 4
    dest = Array(dest).first
    case dest
    when Item
      do_move(klass, 'in', item, 'default', msg_out, msg_in)
    when ItemDetail
      do_move_to_location(klass, dest, msg_out, msg_in)
    else
      false
    end
  end

  def script_MoveTo5 machine, objs
    msg_in, msg_out, dest, prep, klass = machine.pop 5
    dest = Array(dest).first
    case dest
    when Item
      # move to being _prep_ Item _default_
      do_move(klass, prep, dest, 'default', msg_out, msg_in)
    when ItemDetail
      # move to being in the relationship described by ItemDetail
      do_move(klass, prep, dest.item, dest.coord, msg_out, msg_in)
    else
      # we don't move
      false
    end
  end

  ##
  # Perform(skill, pro, con)
  #
  # skill: string naming the skill being used
  # pro: bonus in actor's favor
  # con: bonus against actor
  #
  # Result is true if the actor can perform the action with the skill
  # Any training notifications are made here with appropriate events
  #   to this object.
  #
  def script_Perform3 machine, objs
    #skill, pro, con
    con, pro, skill = machine.pop 3
    if objs[:direct]
      con += objs[:direct].first.trait(skill_defense_for(skill))
    end
    if objs[:instrument]
      pro += objs[:instrument].first.trait(skill_aid_for(skill))
    end
  end

  ##
  # Create(archetype)
  #
  def script_Create1 machine, objs
    nom = machine.pop 1
    nom = SecondContract::Game.instance.find_archetype_name(archetype_name, nom)
    arch = SecondContract::Game.instance.get_archetype(nom)
    if arch.nil?
      obj = nil
    else
      obj = Item.create(archetype_name: nom)
      obj.do_move('create', :near, self, 'default', '', '')
    end
    @stack.push obj
  end

  ##
  # Destruct()
  #
  def script_Destruct0 machine, objs
    do_move('destroy', nil, nil, nil, '', '')
    objects = sources.all
    while objects.any?
      obj = objects.pop
      objects.push obj.sources
      obj.source_relationships.clear
    end
  end
end
