require 'eventmachine'

module SecondContract::Service
end

class SecondContract::Service::Admin < EventMachine::Connection
  def server
    SecondContract::Driver.instance
  end

  def game
    SecondContract::Game.instance
  end
  
  def post_init
    send_data("Second Contract Administrative Console\n\n> ")
  end

  def receive_data(data)
    data.strip!
    bits = data.split(/\s+/, 2)
    cmd = "cmd_" + bits.first
    if respond_to?(cmd)
      self.send(cmd, bits.last)
    else
      send_data(data)
    end
    send_data("\n> ")
  end

  def unbind
    server.admin_connections.delete(self)
    close_connection
  end

  def cmd_quit(arg)
    unbind
  end

  def cmd_shutdown(arg)
    unbind
    server.stop
  end

  def cmd_shutdown!(arg)
    unbind
    server.full_stop
  end

  def cmd_status(arg)
    send_data(
      "Players: #{server.player_connections.length}\t" +
      "Admins: #{server.admin_connections.length}\n" +
      "Objects: #{Item.count}\tArchetypes: #{game.archetypes.length}\n" +
      "Domains: #{Domain.count}\n"
    )
    if server.stopping
      send_data("\nThe server is in the processes of shutting down.\n")
    end
  end

  def cmd_domain(arg)
    bits = arg.split(/\s+/)
    cmd = "cmd_domain_#{bits.first}"
    if respond_to?(cmd)
      self.send(cmd, *bits.drop(1))
    else
      send_data("Available domain commands: load")
    end
  end

  def cmd_domain_load(args)
    if args.length != 1
      send_data("'domain load' expects a domain name")
    end

  end
end