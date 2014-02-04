require 'eventmachine'
require 'active_record'
require 'singleton'

module SecondContract
end

class SecondContract::Driver
  include Singleton

  require 'second-contract/game'

  attr_accessor :host, :port, :player_connections, :admin_connections, :stopping, :game

  def config(config)
    @game = SecondContract::Game.instance
    @game.config(config)
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
  end

  def start_admin
    require 'second-contract/service/admin'
    admin_host = '127.0.0.1'
    admin_port = @config['services']['admin']['port']

    puts "Starting telnet service on 127.0.0.1:#{admin_port}"
    @signatures << EventMachine::start_server(
      '127.0.0.1', 
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