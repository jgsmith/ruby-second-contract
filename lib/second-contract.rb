require 'eventmachine'
require 'active_record'
require 'singleton'
require 'eventmachine'
require 'optparse'
require 'yaml'

I18n.enforce_available_locales = false

class SecondContract
  module IFLib
    module Sys
    end
    module Data
    end
  end

  def self.config(argv = [], environment = "production")
    options = {
      environment: environment
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: driver [options] config.yml"

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end

      opts.on("-c", "--check", "Check syntax only") do |c|
        options[:check] = c
      end

      opts.on("-e", "--env", "Set environment type") do |e|
        options[:environment] = e
      end
    end.parse!(argv)

    # ARGV should have a config file now
    if argv.length == 1
      config_file = argv[0]
    else
      config_file = "config/game.yml"
    end

    def do_deep_merge v1, v2
      if v1.is_a?(Hash) && v2.is_a?(Hash)
        v1.merge(v2) { |k, vv1, vv2| do_deep_merge(vv1, vv2) }
      elsif v1.is_a?(Array) && v2.is_a?(Array)
        v1 + v2
      else
        v2
      end
    end

    config_content = YAML.load_file(config_file)
    config = {}
    if config_content.include?('all')
      config.merge!(config_content['all'])
    end
    if config_content.include?(options[:environment])
      config.merge!(config_content[options[:environment]]) { |k, v1, v2| do_deep_merge(v1, v2) }
    else
      puts "Unable to find #{options[:environment]} configuration in #{config_file}"
      exit 0
    end

    config['verbose'] = options['verbose']

    if !options[:check]
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection
    else
      config[:checkSyntaxOnly] = true
    end

    SecondContract::Game.instance.config(config)

    config
  end

  def self.run(argv = [], environment = "production")
    options = self.config(argv, environment)
    if options[:checkSyntaxOnly]
      SecondContract::Game.instance.compile_all
    else
      EventMachine::run {
        SecondContract::Driver.instance.config(options).start
      }
    end
  end
end

class SecondContract::Driver
  include Singleton

  require 'second-contract/game'

  attr_accessor :host, :port, :player_connections, :admin_connections, :stopping, :game



  def config(config)
    @game = SecondContract::Game.instance
    @admin_connections = []
    @player_connections = []
    @signatures = []
    @stopping = false
    @config = config
    self
  end

  def start
    setup_signals

    @game.start

    start_telnet if @config['services']['telnet']
    start_admin  if @config['services']['admin']
  end

  def stop
    if !@stopping
      @stopping = true
      @signatures.each do |s|
        EventMachine.stop_server(s)
      end
      puts "Shutting down gracefully"
      unless wait_for_connections_and_stop
        puts "Waiting for #{@admin_connections.length + @player_connections.length} connection(s) to finish..."
        EventMachine.add_periodic_timer(1) {
          wait_for_connections_and_stop
        }
      end
    end
  end

  def full_stop
    puts "Shutting down."
    if !@stopping
      @stopping = true
      @signatures.each do |s|
        EventMachine.stop_server(s)
      end
      EventMachine.stop
    end
  end

  def wait_for_connections_and_stop
    if @admin_connections.empty? && @player_connections.empty?
      EventMachine.stop
      true
    else
      #puts "Waiting for #{@admin_connections.length + @player_connections.length} connection(s) to finish..."
      false
    end
  end

private
  def start_telnet
    require 'second-contract/service/telnet'
    telnet_port = @config['services']['telnet']['port']
    telnet_host = @config['services']['telnet']['host'] || '0.0.0.0'

    puts "Starting telnet service on #{telnet_host}:#{telnet_port}"
    @signatures << EventMachine::start_server(
      telnet_host, 
      telnet_port, 
      SecondContract::Service::Telnet
    ) do |conn|
      @player_connections << conn
      conn.start
    end

    EventMachine.add_periodic_timer(0.5) {
      @player_connections.select{|s| s.should_disconnect }.each do |s|
        s.unbind
      end
    }
  end

  def start_admin
    require 'second-contract/service/admin'
    admin_host = '127.0.0.1'
    admin_port = @config['services']['admin']['port']

    puts "Starting admin service on 127.0.0.1:#{admin_port}"
    @signatures << EventMachine::start_server(
      admin_host, 
      admin_port, 
      SecondContract::Service::Admin
    ) do |conn|
      @admin_connections << conn
    end
  end

  def setup_signals
    Signal.trap("INT") do
      stop 
    end

    Signal.trap("TERM") do
      if @stopping
        full_stop
        exit 0
      else
        full_stop
      end
    end
  end
end
