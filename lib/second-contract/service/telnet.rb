require 'eventmachine'

module SecondContract::Service
end

class SecondContract::Service::Telnet < EventMachine::Connection
  def initialize
    @state = :START
    @character = nil
    @info = {}
    @echo = true
    @user = nil
  end

  def server
    SecondContract::Driver.instance
  end

  def game
    SecondContract::Game.instance
  end

  def start
  	# here's where we send the banner
    iac_wont(:ECHO)
  	send_message(game.banner)
    @state = :start_seq
  end

  def cmd_bits(cmd)
    if cmd.is_a?(Fixnum)
      cmd
    else
      case cmd
      when :ECHO
        1
      else
        0
      end
    end
  end

  def iac_do(cmd)
    bit = cmd_bits(cmd)
    if bit
      send_message([255, 253, bit].pack("C*"))
    end
  end

  def iac_dont(cmd)
    bit = cmd_bits(cmd)
    if bit
      send_message([255,254, bit].pack("C*"))
    end
  end

  def iac_will(cmd)
    bit = cmd_bits(cmd)
    if bit
      send_message([255, 251, bit].pack("C*"))
    end
  end

  def iac_wont(cmd)
    bit = cmd_bits(cmd)
    if bit
      send_message([255, 252, bit].pack("C*"))
    end
  end

  def process_iac chars
    return
    case chars[0]
    when 251
      if chars[1] != 1
        iac_dont(chars[1])
      else
        iac_dont(chars[1])
      end
    when 253
      if chars[1] != 1
        iac_wont(chars[1])
      else
        iac_wont(chars[1])
      end
    end
  end

  # receive_data needs to manage telnet negotiation before passing the data along
  def receive_data str
    chars = str.unpack("C*")
    if chars[0] == 255
      puts chars.join(",")
      process_iac(chars.drop(1))
    else

      case receive_message str
      when :NOECHO
        #iac_do(:ECHO)
        #@buffer = ""
        #@echo = false
        iac_will(:ECHO)
        @buffer = ""
        @echo = false
      when :DISCONNECT
        send_message("\n\n")
        unbind
      else
        iac_wont(:ECHO)
        # echo
      end
    end
  end

  def receive_message str
    str.strip!
    ret = send(@state, str)
    if ret.nil?
      :DISCONNECT
    elsif ret.is_a?(Array)
      @state = ret.first
      ret.last
    else
      @state = ret
      :ECHO
    end
  end

  def send_message str
    send_data(str.gsub(/\n/, "\x0d\x0a"))
  end

  def emit klass, text
    # eventually, color code based on klass
    send_data(text + "\n")
  end

  def normal str  
    if str.start_with?('%')
      # command
      :normal
    elsif str == 'quit'
      send_message("Please come again!\n")
      # leave game
      nil
    else
      if !game.run_command(@character, str)
        send_message("what?\n")
      end
      :normal
    end
  end

  def new_account str
    if !str || str == ""
      send_message("\nPerhaps another time.\n")
      nil
    elsif game.user_exists?(str)
      send_message("\nThat user already has an account.")
      nil
    else
      @info[:email] = str
      send_message("Select a password: ")
      [ :newaccount_passwd, :NOECHO ]
    end
  end

  def newaccount_passwd str
    if !str || str == ""
      send_message("\nPerhaps another time.\n")
      nil
    elsif game.user_exists?(@info[:email])
      send_message("\nThat user already has an account.")
      nil
    else
      @info[:newpassword] = str
      send_message("\nRetype password: ")
      [ :newaccount_password2, :NOECHO ]
    end
  end

  def newaccount_password2 str
    if !str || str == ""
      send_message("\nPerhaps another time.\n")
      nil
    elsif @info[:newpassword] != str
      send_message("\nThose passwords don't match. Please come back and try again another time.")
      nil
    elsif game.user_exists?(@info[:email])
      send_message("\nThat user already has an account.")
      nil
    else
      game.set_user_password(@info[:email], @info[:newpassword])
      send_message("\nNow we'll walk you through creating your first character.")
      send_message("\n\nWhat name do you wish? ")
      :new_character
    end
  end

  def new_character str
    if !str || str == ""
      send_message("\nPerhaps another time.\n")
      nil
    elsif game.character_exists?(str)
      send_message("\nA character by that name already exists.\n\nWhat name do you wish? ")
      :new_character
    else
      send_message("\nAre you sure you want \"#{str}\"? (Y/n) ")
      @info[:name] = str
      :new_char_name_confirm
    end
  end

  def new_char_name_confirm str
    if str == "Y" || str == "y" || str == ""
      send_message("\nHow would you like your name capitalized? (\"#{@info[:name].capitalize}\") ")
      :new_char_cap_name
    else
      send_message("\n\nWhat name do you wish? ")
      :new_character
    end
  end

  def new_char_cap_name str
    if str == ""
      str = @info[:name].capitalize
    end
    send_message("\nAre you sure you want your name capitalized as \"#{str}\"? (Y/n) ")
    @info[:capname] = str
    :new_char_cap_name_confirm
  end

  def new_char_cap_name_confirm str
    if str == 'Y' || str == 'y' || str == ''
      send_message("\nPlease choose an interesting gender (male, female, neutral, or none):\n")
      :new_char_gender
    else
      send_message("\nHow would you like your name capitalized? (\"#{@info[:name].capitalized}\" ")
      :new_char_cap_name
    end
  end

  def new_char_gender str
    case str
    when 'male'
      @info[:gender] = :male
    when 'female'
      @info[:gender] = :female
    when ['neutral','neuter','none']
      @info[:gender] = :neutral
    else
      send_message("Please choose an interesting gender (male, female, neutral, or none):\n")
      return :new_char_gender
    end

    send_message("\nPreparing to enter the game as #{@info[:capname]}.\n")
    @info[:archetype] = 'std:human'
    @character = create_character(@info)
    if !@character
      send_message("\nSomething went wrong somewhere. We can't seem to find your character.\nPlease try again later.\n\n")
      nil
    else
      if enter_game
        send_message("> ")
        :normal
      else
        send_message("\nUnable to enter the game for some reason.\n\n")
        nil
      end
    end
  end

  def login str
    @user = game.authenticate_user(@info[:email], str)
    if !@user
      send_message("\nBad password.\n")
      nil
    else
      send_message("\n")
      # need to send bits to turn echo on
      @chars = @user.characters
      if @chars.empty?
        send_message("\nNow we'll walk you through creating your first character.")
        send_message("\n\nWhat name do you wish? ")
        @state = :NEW_CHARACTER
        :new_character
      else
        send_message("\n\nPlease select a character to play:\n")
        @chars.each_with_index do |i,char|
          send_message("#{i+1}) #{char.get_name}\n")
        end

        if @chars.length < 5
          send_message("\nOr \"N\" to create a new character. You may have up to 5 characters.\n")
        end
        send_message("\nPlease enter an option: ")
        @state = :SELECT_CHARACTER
        :select_character
      end
    end
  end

  def select_character str
    if !str || str == ""
      send_message("\nPerhaps try again another time.\n")
      nil
    else
      case str
      when /^[Nn]$/
        if @chars.length < 5
          send_message("\n\nWhat name do you wish? ")
          @state = :NEW_CHARACTER
          :new_character
        else
          send_message("\nThat isn't a valid option.\n")
          :select_character
        end
      when /^\d+$/
        i = str.to_i
        if i < 1 or i > @chars.length
          send_message("\nThat isn't a valid option.\n")
          :select_character
        else
          send_message("\nEntering the game as #{@chars[i-1].get_cap_name}.\n\n")
          @character = @chars[i-1]
          @chars = nil
          if enter_game
            :normal
          else
            send_message("\nUnable to enter the game for some reason.\n\n")
            nil
          end
        end
      else
        send_message("\nThat isn't a valid option.\n")
        :select_character
      end
    end
  end

  def start_seq str
    str.downcase!
    if !str || str == ""
      :nil
    elsif game.user_exists?(str)
      send_message("Password: ")
      @info[:email] = str
      [ :login, :NOECHO ]
    elsif str == 'n' || str == 'N'
      # new user
      send_message("What's your e-mail? ")
      :new_account
    else
      send_message("That user doesn't exist here.\n")
      nil
    end
  end

  def enter_game
    if !@character.bind(self)
      @character = nil
      false
    end
    true
  end

  def create_character info
    # we want to create an item and connect it to a character object
    # that is connected to the logged in user
    item = Item.new(
      archetype: 'std:character',
      traits: {
        name: info[:name],
        capName: info[:capName],
      },
      physical: {
        gender: info[:gender],
      }
    )
    @user.characters.build({
      name: info[:name]
    })
  end

  def unbind
    if !@character.nil?
      @character.unbind
    end
  	server.player_connections.delete(self)
  	close_connection
  end
end