require 'singleton'

class SecondContract::Game
  attr_accessor :banner

  include Singleton

  require 'pathname'
  require 'second-contract/parser/script'
  require 'second-contract/parser/grammar'
  require 'second-contract/game/event'
  require 'second-contract/compiler/message'
  require 'second-contract/game/event_set'
  require 'second-contract/model/user'
  require 'second-contract/model/character'
  require 'second-contract/model/item'
  require 'second-contract/model/archetype'
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

  def config(config)
    @banner = "Welcome to #{config['name']}!\n"
    @game_dir = Pathname.new(File.join(Dir.pwd, config['game'])).cleanpath.to_s
    if !File.directory?(@game_dir)
      puts "Game directory (#{config['game']} does not exist"
      exit 0
    end

    if File.file?(File.join(@game_dir, 'text', 'welcome.txt'))
      @banner = File.read(File.join(@game_dir, 'text', 'welcome.txt'))
    end

    @compiler = SecondContract::Parser::Script.new
    @parser   = SecondContract::Parser::Grammar.new
    @archetypes = {}
    @pending_archetypes = SecondContract::Game::SortedHash.new(:ur)
    @pending_traits = SecondContract::Game::SortedHash.new(:mixins)
    @traits = {}
    @verbs = {}
    @adverbs = {}
    @comm_verbs = {}

    @events = []

    @message_parser = SecondContract::Parser::Message.new
    @message_formatter = SecondContract::Compiler::Message.new
    self
  end

  ##
  # call-seq:
  #   SecondContract::Game.instance.compile_all => self
  #
  # 
  def compile_all
    compile

    if !@pending_traits.empty?
      # now we need a dependency graph so we can order traits properly
      @pending_traits.sorted_keys.each do |name|
        info = @pending_traits[name]

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
        if info[:archetype] && !@archetypes[info[:archetype]]
          puts "Archetype #{info[:archetype]} not defined, but required by #{name}"
        end
        
        regularize_traits info

        item = Archetype.new(info)
        if !reported_errors? item
          item.name = name
          @archetypes[name] = item
        end
        @pending_archetypes.delete name
      end
      if !@pending_archetypes.empty?
        puts "Some archetypes were not defined: #{@pending_archetypes.keys.sort.join(", ")}"
      end
      @pending_archetypes = nil
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

  def comm_verbs
    @comm_verbs.keys
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
          compile_domain_data(fullPath, bits)
        end
      end
    end
  end

  def compile_domain_data fullPath, bits
    case bits[2]
    when "map.yaml"
      data = YAML.load_file(fullPath)
      # we want to ensure that the items in the map are in the object db
      # we mark them as being from the map - we don't remove rooms that
      # didn't come from a map in the first place
    when "hospital.yaml"
      data = YAML.load_file(fullPath)
      # we will need to run through an inventory everything - and things that
      # were instantiated by the hospital but aren't needed should be removed
    end
  end

  def compile_verb fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      tree = @compiler.parse_verb(IO.read(fname))
      if tree[:verbs]
        tree[:verbs].each do |v|
          @verbs[v] = [] unless @verbs[v]
          @verbs[v] << tree
        end
      end
    end
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
      colonName = filename2colonname fname
       
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

  def get_archetype name
    if @archetypes[name].nil?
      compile_archetype(File.send(:join, [ @game_dir ] + name.split(':')) + ".sc")
    end
    @archetypes[name]
  end

  def compile_trait fname
    fname = Pathname.new(fname).cleanpath.to_s
    if is_file?(fname)
      colonName = filename2colonname fname
       
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

  def narrative event_name, volume, message, objects
    parsed_message = @message_parser.parse(message)
    if !@message_parser.errors?
      # we want to run through each of the objects and then the environment of
      # objects[:this]
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
          if nextSet = set.get_previous
            set = nextSet
          end
        end
        nextSet = set
      else
        set.get_consequents(true).each { |e| call_event e }
        nextSet = set.get_next
      end
    end

    nextSet = set
    
    while nextSet
      set = nextSet

      guard_result = set.run_guards(false)

      return true if guard_result != 1

      set.get_consequents(false).each { |e| call_event e }

      set.get_reactions(false).each { |e| queue_event e }

      nextSet = set.get_previous
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
    Character.where(:name => name).count == 1
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

  def regularize_traits info
    info[:traits].reject{ |t| @traits.include?(t) || info[:qualities].include?(t) }.each do |t|
      info[:qualities][t] = [ :CONST, 'True' ]
    end

    info[:traits] = info[:traits].select{|t| @traits.include?(t)}.inject({}) { |h, k| h[k] = @traits[k]; h }
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

  def filename2colonname fname
    fname[@game_dir.length..fname.length-1].
      sub(/\.[^.]*$/,'').
      gsub(File::SEPARATOR, ':').
      sub(/:traits:/, ':').
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