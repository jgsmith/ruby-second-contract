##
# Objects are items in the game of any type that inherit from an
# archetype. Archetypes are defined outside the database, so they
# aren't an ActiveRecord class.
#
# Objects only inherit from an archetype - any mixins/traits must be
# included in the archetype.
#
require 'second-contract/game/systems'

class Item < ActiveRecord::Base
  include SecondContract::Game::Systems

  validates_presence_of :archetype
  validates_presence_of :type

  serialize :skills, Hash
  serialize :traits, Hash
  serialize :details, Hash
  serialize :stats, Hash
  serialize :physicals, Hash
  serialize :counters, Hash
  serialize :resources, Hash

  has_one :character, inverse_of: :item

  has_many :target_relationships, class_name: "ItemRelationship", foreign_key: :source_id
  has_many :source_relationships, class_name: "ItemRelationship", foreign_key: :target_id

  has_many :targets, through: :target_relationships
  has_many :sources, through: :source_relationships

  def initialize
    super
    initialize_systems
  end

  def archetype
    @archetype_obj ||= SecondContract.game.get_archetype(read_attribute(:archetype))
    @archetype_obj
  end

  def archetype= obj
    if @archetype_obj != obj
      @archetype_obj = obj
      write_attribute(:archetype, obj.name)
    end
  end

  def validated? prefix, name
    if archetype.nil?
      false
    else
      archetype.validated?(prefix, name)
    end
  end

  def validate prefix, name, value, objs = {}
    if archetype.nil?
      true
    else
      archetype.validate(prefix, name, value, objs)
    end
  end

  def calculated? prefix, name
    if archetype.nil?
      false
    else
      archetype.calculated?(prefix, name)
    end
  end

  def calculate prefix, name, objs = {}
    if archetype.nil?
      nil
    else
      archetype.calculate(prefix, name, objs.merge({this: self}))
    end
  end

  def get_environment
    # returns the object in which this item is located
    options = targets.group_by{ |t| t.preposition }
    if !options[:in].empty?
      options[:in].first
    end
  end

  def get_inventory
    # returns a list of items contained within this item - for which
    # their environment method returns this object
  end

  def trigger_event evt, objs
    SecondContract::Game.instance.call_event(
      SecondContract::Game::Event.new(self, evt, objs)
    )
  end

  def has_event_handler? evt
    archetype && archetype.has_event_handler?(evt)
  end
  
  def call_event_handler evt, args
    if archetype
      archetype.call_event_handler(evt, args)
    else
      nil
    end
  end

  def script_Emit2 machine, objs, env
    # klass, text
    klass, text = machine.pop 2
    if !character.nil?
      character.emit klass, text
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
  def script_Perform3 machine, objs, env
    #skill, pro, con
    skill, pro, con = machine.pop 3
    if objs[:direct]
      con += objs[:direct].first.trait(skill_defense_for(skill))
    end
    if objs[:instrument]
      pro += objs[:instrument].first.trait(skill_aid_for(skill))
    end
  end
end

class Scene < Item
end

class Path < Item
end

class Terrain < Item
end