require 'singleton'

class SecondContract::Game
  attr_accessor :banner, :constants

  include Singleton

  require 'pathname'
  require 'second-contract/parser/script'
  require 'second-contract/parser/grammar'
  require 'second-contract/iflib/sys/binder'
  require 'second-contract/iflib/data/verb'
  require 'second-contract/game/event'
  require 'second-contract/compiler/message'
  require 'second-contract/game/event_set'
  require 'second-contract/model/user'
  require 'second-contract/model/character'
  require 'second-contract/model/item'
  require 'second-contract/model/archetype'
  require 'second-contract/model/domain'
  require 'second-contract/model/trait'
  require 'second-contract/game/sorted-hash'


  ##
  # call-seq: 
  #   SecondContract::Game.instance.config(config) => self
  #
  # Returns the game instance object.
  #
  # Configures the game instance given the configuration hash.
  # Typically, this is the same hash as provided to the SecondContract
  # instance.
  #

  def config(config = nil)
    if config.nil?
      return @config
    end

    @config = config

    @banner = "Welcome to #{config['name']}!\n"
    @game_dir = Pathname.new(File.join(Dir.pwd, config['game'] || 'game')).cleanpath.to_s
    if !File.directory?(@game_dir)
      puts "Game directory (#{config['game']} does not exist"
      exit 0
    end

    if File.file?(File.join(@game_dir, 'text', 'welcome.txt'))
      @banner = File.read(File.join(@game_dir, 'text', 'welcome.txt'))
    end

    @compiler = SecondContract::Parser::Script.new
    @parser   = Grammar.new
    @binder = SecondContract::IFLib::Sys::Binder.instance
    @archetypes = {}
    @pending_archetypes = SecondContract::Game::SortedHash.new(:archetype)
    @pending_traits = SecondContract::Game::SortedHash.new(:mixins)
    @traits = {}
    @verbs = {}
    @adverbs = {}
    @comm_verbs = {}
    @constants = config['constants'] || {}
    @characters = []
    @bindings = []
    @domains = {}

    @events = []

    @pending = []

    @message_parser = SecondContract::Parser::Message.new
    @message_formatter = SecondContract::Compiler::Message.new
    self
  end

  def path_to(*path)
    Pathname.new(File.join(@game_dir, *path)).cleanpath.to_s
  end

  ##
  # call-seq:
  #   SecondContract::Game.instance.compile_all => self
  #
  # 
  def compile_all
    compile

    vtypes = {}

    @verbs.values.each do |vs|
      vs.each do |v|
        v.verbs.each do |vv|
          if vtypes[vv].nil?
            vtypes[vv] = v.type
          else
            if vtypes[vv] != v.type
              puts "*** Verb #{vv} has multiple types (#{vtypes[vv]} and #{v.type})"
            end
          end
        end
      end
    end
    vtypes.each do |pair|
      @parser.add_verb(pair.last, pair.first)
    end

    @adverbs.keys.each do |a|
      @parser.add_adverb(a)
    end

    if !@pending_traits.empty?
      # now we need a dependency graph so we can order traits properly
      @pending_traits.sorted_keys.each do |name|
        info = @pending_traits[name]
        info[:name] = name
        regularize_traits info

        item = Trait.new(info)

        if !reported_errors? item
          @traits[name] = item
        end

        @pending_traits.delete name
      end
    end

    if !@pending_archetypes.empty?
      # now we need a dependency graph so we can order archetypes properly
      @pending_archetypes.sorted_keys.each do |name|
        info = @pending_archetypes[name]
        if !info.nil?
          if info[:archetype]
            archetype_name = find_archetype_name name, info[:archetype]
            if !@archetypes[archetype_name]
              puts "Archetype #{info[:archetype]} not defined, but required by #{name}"
              info[:archetype] = nil
            else
              info[:archetype] = @archetypes[archetype_name]
            end
          end

          info[:name] = name
          regularize_traits info

          item = Archetype.new(info)
          if !reported_errors? item
            @archetypes[name] = item
          end
          @pending_archetypes.delete name
        end
      end
      if !@pending_archetypes.empty?
        puts "Some archetypes were not defined: #{@pending_archetypes.keys.sort.join(", ")}"
      end
      @pending_archetypes = nil
    end

    @pending.each do |p|
      self.send(p.first, *p.last)
    end

    self
  end

  def start
    compile_all

    EventMachine.add_periodic_timer(0.25) {
      event_beat
    }

    EventMachine.add_periodic_timer(2) {
      # object heartbeat
    }

    EventMachine.add_periodic_timer(0.5) {
      # combat heartbeat
    }
  end

  def verbs
    @verbs.keys
  end

  def adverbs
    @adverbs.keys
  end

  def archetypes
    @archetypes.keys
  end

  ##
  # Loads everything into the game - compiles verbs, adverbs, archetypes, etc.
  #
  def compile dir = nil
    if dir.nil?
      dir = @game_dir
    end

    valid_dir_entries(dir).each do |d|
      fullPath = File.join(dir, d)

      if File.directory?(fullPath)
        compile File.join(dir, d)
      elsif File.file?(fullPath)
        bits = fullPath[@game_dir.length+1..fullPath.length-1].split(File::SEPARATOR)
        if bits.include?('archetypes')
          compile_archetype(fullPath)
        elsif bits.include?('traits')
          compile_trait(fullPath)
        elsif bits.include?('verbs')
          compile_verb(fullPath)
        elsif bits.include?('adverbs')
          compile_adverb(fullPath)
        elsif bits[0] == 'domains' && bits.length == 3
          @pending << [ :compile_domain_data, [ fullPath, bits ]]
        end
      end
    end
  end

  def get_domain name
    if !@domains[name]
      @domains[name] = Domain.find_by(:name => name)
      if !@domains[name]
        @domains[name] = Domain.create!({ :name => name })
      end
    end
    @domains[name]
  end

  def compile_domain_data fullPath, bits
    case bits[2]
    when "map.yaml"
      data = YAML.load_file(fullPath)
      domain = get_domain(bits[1])
      domain.load_map(data)
      # we want to ensure that the items in the map are in the object db
      # we mark them as being from the map - we don't remove rooms that
      # didn't come from a map in the first place
    when "hospital.yaml"
      data = YAML.load_file(fullPath)
      domain = get_domain(bits[1])
      domain.load_hospital(data)
      # we will need to run through an inventory everything - and things that
      # were instantiated by the hospital but aren't needed should be removed
    end
  end

  def compile_verb fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      tree = @compiler.parse_verb(IO.read(fname))
      verb = SecondContract::IFLib::Data::Verb.new(tree)
      if !verb.disabled?
        verb.verbs.each do |v|
          @verbs[v] = [] unless @verbs[v]
          @verbs[v] << verb
        end
      end
    end
  end

  def get_verbs verb
    @verbs[verb] || []
  end

  def compile_adverb fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      tree = @compiler.parse_adverb(IO.read(fname))
      adverb = File.basename(fname)
      @adverbs[adverb] = tree
    end
  end

  def compile_archetype fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      colonName = filename2colonname 'archetypes', fname
       
      content = IO.read(fname)
      if fname.end_with?('.sc')
        tree = @compiler.parse_archetype(content)
      elsif fname.end_with?('.yaml')
        yaml = YAML.load(content)
        tree = { data: {} }
        tree[:archetype] = yaml['archetype'] if yaml['archetype']
        tree[:constant_data] = yaml
      end
      if tree.nil?
        puts @compiler.errors.yaml
      else
        @pending_archetypes[colonName] = tree
      end
    end
  end

  def register_archetype name, archetype
    @archetypes[name] = archetype
  end

  def get_archetype name
    @archetypes[name]
  end

  def compile_trait fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      colonName = filename2colonname 'traits', fname
       
      content = IO.read(fname)
      tree = @compiler.parse_trait(content)
      if tree.nil?
        puts @compiler.errors.yaml
        false
      else
        @pending_traits[colonName] = tree
        true
      end
    end
  end

  def run_command actor, string
    parse = @parser.parse(string)
    if @parser.failed?
      return false
    end
    bindings = @binder.bind(actor, parse)
    bindings.each do |b|
      if !b.execute(actor)
        return false
      end
      term_for_item(actor.id).try(:flush_messages)
    end
    return true
  end

  def enter_game char_item, term
    # get last position of character and move them there
    @characters |= [ char_item ]
    if @bindings[char_item.id]
      @bindings[char_item.id].unbind
    end
    @bindings[char_item.id] = term
    loc = char_item.get_location
    loc.item.trigger_event("pre-game:enter", {
      this: loc.item,
      actor: char_item
    })
    tr = char_item.target_relationships.where(:target => loc.item).first
    tr.hidden = false
    tr.save!
    char_item.reload
    char_item.trigger_event("pre-scan:brief-actor", {
      this: char_item,
      actor: char_item
    })
    char_item.trigger_event("post-scan:brief-actor", {
      this: char_item,
      actor: char_item
    })
    loc.item.trigger_event("post-game:enter", {
      this: loc.item,
      actor: char_item
    })
    true
  end

  def term_for_item item
    if @bindings[item]
      @bindings[item]
    elsif item.try(:id) && @bindings[item.id]
      @bindings[item.id]
    end
  end

  def leave_game char_item
    if @characters.include?(char_item)
      @characters -= [ char_item ]
      # need to save last position of character object
    end
    true
  end

  def characters
    @characters
  end

  def emit_to character_id, klass, text
    if !@bindings[character_id].nil?
      @bindings[character_id].emit klass, text
    end
  end

  def narrative event_name, volume, message, objects
    parsed_message = message.is_a?(String) ? @message_parser.parse(message) : message
    if !@message_parser.errors?
      # we want to run through each of the objects and then the environment of
      # objects[:this]
      #msg:sight:env
      #
      shown = []
      if objects[:actor]
        shown << objects[:actor]
        if objects[:actor].has_event_handler?(event_name + '-actor')
          evt = event_name + '-actor'
        else
          evt = event_name + '-any'
        end
        objects[:actor].trigger_event(evt, objects.merge({
          text: @message_formatter.format(objects[:actor], parsed_message, objects),
          volume: volume
        }))
      end
      %i(direct indirect instrument).each do |pos|
        if objects[pos]
          objects[pos].each do |direct|
            if !shown.include?(direct)
              shown << direct
              if direct.has_event_handler?(event_name + '-' + pos.to_s)
                evt = event_name + '-' + pos.to_s
              else
                evt = event_name + '-any'
              end
              direct.trigger_event(evt, objects.merge({
                text: @message_formatter.format(direct, parsed_message, objects),
                volume: volume
              }))
            end
          end
        end
      end
      # eventually, we need to let the environment around actor know
    end
  end

  def queue_event event
    if matches_current_event? event
      false
    else
      @events.push event
      true
    end
  end

  def call_event event
    if matches_current_event? event
      false
    else
      ce = @current_event
      @current_event = event
      ret = event.handle
      @current_event = ce
      ret
    end
  end

  def event_beat
    while !@events.empty?
      @current_event = @events.shift
      @current_event.handle
      @current_event = nil
    end
  end

  def run_event_set set
    nextSet = set
    
    while nextSet
      
      set = nextSet
      
      guard_result = set.run_guards(true)

      case guard_result
      when FalseClass
        return false
      when Fixnum
        guard_result.times do
          if nextSet = set.get_previous_set
            set = nextSet
          end
        end
        nextSet = set
      else
        set.get_consequents(true).each { |e| call_event e }
        set.get_reactions(true).each { |e| call_event e }
        nextSet = set.get_next_set
      end
    end

    nextSet = set
    
    while nextSet
      set = nextSet

      guard_result = set.run_guards(false)

      return true if guard_result != true

      set.get_consequents(false).each { |e| call_event e }

      set.get_reactions(false).each { |e| queue_event e }

      nextSet = set.get_previous_set
    end
    return true
  end

  ## Character/User related methods
  def user_exists? email
    User.where(:email => email).count == 1
  end

  def set_user_password email, passwd
    user = User.where(:email => email).first_or_create
    user.password = passwd
    user.save!
  end

  def authenticate_user email, passwd
    User.where(:email => email, :password => passwd).first
  end

  def character_exists? name
    # this is a bit more difficult because the character is an object in the game
    #
    Character.where(:name => name.downcase).count == 1
  end

  def create_character user, info
    # we want to create an item and connect it to a character object
    # that is connected to the logged in user
    #ActiveRecord::transaction do
    if user.characters.count < 5
      start_info = @config['start']
      if start_info.nil? || start_info['target'].nil?
        puts "*** No start location information - aborting character creation"
        return false
      end
      start_env_bits = start_info['target'].split(/:/, 2)
      if @domains[start_env_bits.first].nil?
        puts "*** Start domain is not found - aborting character creation"
        return false
      end
      start_env = @domains[start_env_bits.first].get_item(start_env_bits.last)
      if start_env.nil?
        puts "*** Start environment is not found - aborting character creation"
        return false
      end

      item = Item.create(
        archetype_name: info[:archetype]
      )
      item.set_detail('default:name', info[:name].downcase)
      item.set_detail('default:capName', info[:capname])
      item.set_physical('gender', info[:gender])
      item.set_physical('position', 'standing')
      item.save!
      char = user.characters.create!({
        name: info[:name].downcase,
        item: item
      })
      r = item.target_relationships.create!({
        target: start_env,
        preposition: (start_info['preposition'] || 'in').to_sym,
        detail: (start_info['detail'] || 'default'),
        hidden: true
      })
      return char
    end
  end

private

  def is_file? fname
    if !File.file?(fname)
      puts "#{fname[@game_dir.length..fname.length-1]} is not a file"
      false
    else
      true
    end
  end

  def find_name set, path, name

    if set.include?(name)
      return name
    end

    bits = path.split(/:/)
    while !bits.empty?
      bits.pop
      if set.include?(bits.join(":") + ":" + name)
        return bits.join(":") + ":" + name
      end
    end
    nil
  end

  def find_trait_name path, name
    find_name @traits, path, name
  end

  def find_archetype_name path, name
    find_name @archetypes, path, name
  end

  def regularize_traits info
    mixins = info[:traits].partition{ |t| 
      info[:qualities].include?(t) || !find_trait_name(info[:name], t).nil?
    }
    mixins.last.each do |t|
      info[:qualities][t] = [ :CONST, 'True' ]
    end

    info[:traits] = mixins.first.inject({}) { |h, k| h[k] = @traits[find_trait_name(info[:name], k)]; h }
  end

  def reported_errors? item
    if item.errors?
      puts "Errors found for #{item.class.name.downcase} #{name}:"
      puts "  " + item.errors.join("\n  ")
      true
    else
      false
    end
  end

  def filename2colonname type, fname
    fname[@game_dir.length..fname.length-1].
      sub(/\.[^.]*$/,'').
      gsub(File::SEPARATOR, ':').
      sub(/:#{type}:/, ':').
      sub(/^:/,'').
      sub(/^domains:/, '')
  end

  def matches_current_event? event
    @current_event && 
    @current_event.type == event.type && 
    event.object == @current_event.object
  end

  def valid_dir_entries dir
    Dir.entries(dir).reject{ |f| f.start_with?('.') }
  end
end
