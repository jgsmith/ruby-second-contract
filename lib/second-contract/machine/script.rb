module SecondContract::Machine
end

require 'second-contract/parser/message'

class SecondContract::Machine::Script
  def initialize code
    @code = code + [ :DONE ]
  end

  def run objs = {}, env = {}
    start
    @objects = objs
    @env = env
    step until @done
    ret = @stack.last
    @stack.clear
    @vars = {}
    ret
  end

  def start
    @ip = 0
    @vars = {}
    @stack = []
    @done = false
  end

  def pop
    @stack.pop
  end

  def push v
    @stack.push v
  end

  def peek
    @stack.last
  end

  def step
    code = @code[@ip]
    @ip += 1
    case code
    when :CLEAR
      @stack.clear
    when :PUSH
      @stack.push @code[@ip]
      @ip += 1
    when :JUMP
      @ip += @code[@ip]
    when :JUMP_UNLESS
      if @stack.pop
        @ip+=1
      else
        @ip += @code[@ip]
      end
    when :CALL
      fctn = "script_" + @code[@ip]
      @ip += 1
      if objs[:this].respond_to? fctn
        @stack.push objs[:this].send(fctn, self, objs, env)
      else
        @stack.push nil
      end
    when :SUM
      do_series_op 0, :+
    when :DIFFERENCE
      @stack.push @stack.pop - @stack.pop
    when :PRODUCT
      do_series_op 1, :*
    when :DIV
      d = @stack.pop
      n = @stack.pop
      if d == 0
        @stack.push 2^63-1
      else
        @stack.push @stack.pop / @stack.pop
      end
    when :MOD
      @stack.push @stack.pop % @stack.pop
    when :SET_VAR
      name = @stack.pop
      value = @stack.last
      @vars[name] = value
    ##
    # Sets the given property in :this and leaves the value
    # on the top of the stack
    #
    when :SET_THIS_PROP
      name = @stack.pop
      value = @stack.last
      bits = name.split(/:/, 2)
      case bits[0]
      when "trait"
        @objects[:this].set_trait(bits[1], value)
      when "skill"
        @objects[:this].set_skill(bits[1], value)
      end
    when :GET_THIS_PROP
      name = @stack.pop
      bits = name.split(/:/, 2)
      case bits[0]
      when "trait"
        @stack.push @objects[:this].trait(bits[1], @objects)
      when "skill"
        @stack.push @objects[:this].skill(bits[1], @objects)
      else
        @stack.push nil
      end
    ##
    # GET_THIS_BASE_PROP
    #
    # Retrieves the value of the property without any intervening calculations
    #
    when :GET_THIS_BASE_PROP
      name = @stack.pop
      bits = name.split(/:/, 2)
      case bits[0]
      when "trait"
        @stack.push @objects[:this].get_trait(bits[1])
      when "skill"
        @stack.push @objects[:this].get_skill(bits[1])
      else
        @stack.push nil
      end
    ##
    # This provides access to :this, :agent, :indirect, etc.
    # -- note that :indirect, :direct, and :instrument might be
    #    arrays of objects (or an object acting on their behalf)
    #
    when :GET_OBJ
      name = @stack.pop
      if @objects.include?(name)
        @stack.push @objects[name] 
      else
        @stack.push nil
      end
    when :GET_VAR
      name = @stack.pop
      @stack.push @vars[name]
    when :GET_PROP
      obj = @stack.pop
      name = @stack.pop
      if !obj.nil?
        bits = name.split(/:/, 2)
        case bits[0]
        when "trait"
          @stack.push obj.trait(bits[1])
        when "skill"
          @stack.push obj.skill(bits[1])
        else
          @stack.push nil
        end
      else
        @stack.push nil
      end
    when :SENSATION
      type = @stack.pop.to_s
      base_volume = @stack.pop.to_s
      vol_adjust = @stack.pop
      message = @message_parser.parse(@stack.pop)
      game.narrative("msg:#{type}:#{base_volume}", vol_adjust, message, @objects)
    when :DONE
      @done = true
    # no :SET_PROP for another object -- objects can only set information on themselves
    # for now -- until we get a use case that requires this functionality
    else
      @ip+=1 until @code[@ip].is_a?(Symbol)
    end
  end

private

  def game
    SecondContract::Game.instance
  end

  def do_series_op init, op
    n = @stack.pop
    if n > 0
      if @stack.last.is_a?(Fixnum)
        @stack.push @stack.pop(n).inject(init.to_i, op)
      else
        @stack.push @stack.pop(n).inject(init.to_f, op)
      end
    else
      @stack.push init
    end
  end
end