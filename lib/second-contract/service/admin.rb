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
    case data
    when "quit"
      unbind
    when "shutdown"
      unbind
      server.stop
    when "shutdown!"
      unbind
      server.full_stop
    when "status"
      send_data(
        "Players: #{server.player_connections.length}\t" +
        "Admins: #{server.admin_connections.length}\n" +
        "Objects: #{Item.count}\tArchetypes: #{game.archetypes.length}\n"
      )
      if server.stopping
        send_data("\nThe server is in the processes of shutting down.\n")
      end
    else
      send_data(data)
    end
    send_data("\n> ")
  end

  def unbind
    server.admin_connections.delete(self)
    close_connection
  end
end