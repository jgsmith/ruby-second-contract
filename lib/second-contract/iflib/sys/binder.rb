class SecondContract::IFLib::Sys::Binder
  include Singleton

  require 'second-contract/iflib/data/command'
  require 'second-contract/iflib/data/context'
  require 'second-contract/iflib/data/match'

  def bind(actor, parse)
    # we want to find all of the different ways in which parse makes sense for actor
    if parse.nil? || parse.empty? || parse[:commands].nil? || parse[:commands].empty?
      return nil
    end

    commands = []

    parse[:commands].each do |cmd|
      ob = SecondContract::IFLib::Data::Command.new
      ob.set_verb(cmd[:verb]) if cmd[:verb]
      ob.add_direct(cmd[:direct]) if cmd[:direct]
      ob.add_indirect(cmd[:indirect]) if cmd[:indirect]
      commands << ob
    end
    commands
  end


  ##
  # bind_direct
  #
  # When binding a direct object, we're looking in the actor's inventory
  # or in the actor's environment's inventory
  #
  # The parse context object tracks things like "my", "her", "she", "him", ...
  #
  def bind_direct(actor, type, phrases)
    bind_objects(actor, type, phrases, [ actor, actor.physical('environment') ].compact)
  end

  #
  # when binding an indirect object, we're looking in the anchor's inventory
  # or in the anchor's environment's inventory, or in the direct objects already matched.
  #
  # The parse context object tracks things like "my", "her", "she", "him",...
  #
  def bind_indirect(actor, type, phrases, direct_obs)
    if type.include?(:direct_inventory)
      default_sources = direct_obs
    else
      default_sources = [ actor, actor.physical('environment') ].compact
    end
    bind_objects(actor, type, phrases, default_sources)
  end

  def bind_exit(actor, phrases)
    exits = actor.get_location.detail_exits( objs: { actor: actor } )
    phrases.each do |d|
      if exits[d.first[:nominal]]
        return d.first[:nominal]
      end
    end
    nil
  end

private

  def match_object_in_array(phrases, ob_list, type, actor)
    context = actor.binder_context
    if context.nil?
      context = SecondContract::IFLib::Data::Context.new
      actor.binder_context = context
    end

    omatch = SecondContract::IFLib::Data::Match.new
    if !phrases || phrases.empty?
      omatch.status = :no_match
      return omatch
    end

    sources = [].concat(ob_list)
    phrases.each do |phrase|
      result = _match_object_in_array( phrase[:preposition] || [ :none, :in, :on, :near, :worn_by, :held_by, :close, :against, :before, :beside, :over ], phrase, sources, type, actor)
      result.objects.each do |ob|
        if ob.is_a?(ItemDetail)
          ob.preposition = 'in'
        end
      end
      omatch.replace_objects(result)
      if result.success?
        sources_now = result.objects
      else
        omatch.status = result.status
        break
      end
    end

    omatch
  end

  #
  # Input: ({ ({ adjs, noun }) })
  # Prep: PREP_...
  #
  # This is used to walk our way from an initial set of objects to the ones
  # we're looking for. The prep indicates the expected relation to the
  # ob_list.
  #
  def _match_object_in_array(prep, input, ob_list, type, actor)
    context = actor.binder_context
    omatch = SecondContract::IFLib::Data::Match.new

    #
    # given the ob_list, prep, and input, we want all of the items with the "prep"
    # relationship to ob_list that satisy the input
    #
    ob_list.each do |ob|
      obs = ob.related_sources(prep)
      if !obs.empty?
        obs.each do |obj|
          result = obj.parse_match_object(input, actor, context)
          if result.first != :no_match
            if result.first.include?(:plural)
              omatch.add_plural_objects(result.last)
            elsif result.first.include?(:singular)
              omatch.add_singular_objects(result.last)
            end
          end
        end
      end
    end

    obs = omatch.objects
    obs.each do |ob|
      if !ob.is_visible_to(actor)
        omatch.remove_object(ob)
      end
    end

    omatch
  end

  def bind_objects(actor, type, phrases, default_sources)
    sources = []

    if type.include?(:in_inventory)
      sources = [ actor ]
    elsif type.include?(:distant)
      env = actor
      while env && !sources.include?(env)
        sources << env
        env = env.physical('environment')
      end
    else
      sources.concat(default_sources)
    end

    if phrases.is_a?(Array) && phrases.first.is_a?(Array)
      # the last should be the 'originating' phrase - the rest use it as the source
      omatch = SecondContract::IFLib::Data::Match.new
      phrases.each do |phrase|
        result = match_object_in_array(phrase, sources, type, actor)
        if result.success?
          omatch.add_objects(result)
        else
          break
        end
      end
    else
      omatch = match_object_in_array(phrases, sources, type, actor)
    end
    if omatch.objects.empty?
      omatch.status = :no_match
    end

    unwanted = omatch.objects.select { |obj|
      objs = { actor: actor, this: obj }
      type.include?(:enter) && !obj.detail('default:enter') ||
      type.include?(:living) && !obj.quality('living', objs) ||
      type.include?(:player) && !obj.quality('player', objs) ||
      type.include?(:wielded) && !obj.quality('wielded', objs) ||
      type.include?(:worn) && !obj.quality('worn', objs)
    }
    omatch.remove_objects(unwanted)

    if type.include?(:singular)
      case omatch.get_singular_objects.length
      when 0
        omatch.status = :no_match
      when 1
      else
        omatch.status = :ambiguous
      end
    elsif omatch.get_plural_objects.empty?
      omatch.status = :no_match
    end

    omatch
  end

  def fixup_context(actor, objects, context)
    if actor.nil? || objects.empty?
      return
    end

    if objects.length > 1
      context.plural_objects = objects
    elsif objects.first.quality('living', {actor: actor, this: objects.first}) && objects.first != actor
      case objects.first.physical('gender', {actor: actor, this: objects.first})
      when 'male'
        context.him = objects.first
      when 'female'
        context.her = objects.first
      else
        context.it = objects.first
      end
    else
      context.it = objects.first
    end

    actor.binder_context = context
  end
end
