module SecondContract::Machine

  class Script
    require 'second-contract/parser/message'

    PROPERTY_TYPES = %w(counter detail flag physical resource skill trait)
    attr_accessor :code
    def initialize code
      @code = code + [ :DONE ]
      @message_parser = SecondContract::Parser::Message.new
    end

    def run objs = {}, env = {}
      start
      @objects = objs
      @env = env
      @objects.each do |key, objs|
        if objs.is_a?(Array)
          objs.each do |obj|
            obj.try(:reload)
          end
        else
          objs.try(:reload)
        end
      end
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
      @stack_marks = []
    end

    def pop n = 1
      @stack.pop n
    end

    def push v
      @stack.push v
    end

    def peek
      @stack.last
    end

    def step
      if @ip > @code.length
        @done = true
        return
      end
      code = @code[@ip]
      @ip += 1
      case code
      when :DUP
        @stack.push @stack.last
      when :DROP
        @stack.pop
      when :MARK
        @stack_marks.push @stack.length
      when :CLEAR
        if !@stack_marks.empty?
          l = @stack_marks.pop
          if l > @stack.length
            @stack.pop(@stack.length - l)
          end
        else
          @stack.clear
        end
      when :PUSH
        @stack.push @code[@ip]
        @ip += 1
      when :JUMP
        @ip += @code[@ip] + 1
      when :JUMP_UNLESS
        v = @stack.pop
        f = case v
            when Array
              v.compact.empty?
            when Hash
              v.empty?
            else
              !v
            end
        if f
          @ip += @code[@ip] + 1
        else
          @ip += 1
        end
      when :NOT
        v = @stack.pop
        @stack.push case v
                    when Array
                      v.compact.empty?
                    when Hash
                      v.empty?
                    else
                      !v
                    end
      when :THIS_CAN
        ability = @stack.pop
        @stack.push @objects[:this].ability(ability, @objects)
      when :THIS_IS
        quality = @stack.pop
        @stack.push @objects[:this].quality(quality, @objects)
      when :UHOH
        @objects[:this].fail_message = SecondContract::Compiler::Message.new.format(
          @objects[:this], @message_parser.parse(@stack.pop), @objects
        )
        @stack.push false
      when :INDEX
        base, idx = @stack.pop(2)
        case base
        when Array
          @stack.push base[idx.to_i]
        when Hash
          @stack.push base[idx]
        else
          @stack.push nil
        end
      when :CALL
        fctn = "script_" + @code[@ip]
        @ip += 1
        fctn += @code[@ip].to_s
        @ip += 1
        @stack.push @objects[:this].try(fctn, self, @objects)
      when :MAKE_LIST
        n = @stack.pop
        @stack.push @stack.pop(n).compact
      when :SUM
        do_series_op 0, :+
      when :CONCAT
        do_series_op "", :+
      when :SET_UNION
        n = @stack.pop
        sets = @stack.pop(n)
        @stack.push sets.drop(1).inject(Array(sets.first)) { |s, x| s = s | Array(x) }
      when :SET_INTERSECTION
        n = @stack.pop
        sets = @stack.pop(n)
        @stack.push sets.drop(1).inject(Array(sets.first)) { |s, x| s = s & Array(x) ; s }
      when :SET_DIFF
        a, b = @stack.pop(2)
        @stack.push(Array(a) - Array(b))
      when :DIFFERENCE
        @stack.push @stack.pop - @stack.pop
      when :PRODUCT
        do_series_op 1, :*
      when :AND
        do_series_op true, :and
      when :OR
        do_series_op false, :or
      when :LT
        do_ordered_op :<
      when :GT
        do_ordered_op :>
      when :LE
        do_ordered_op :<=
      when :GE
        do_ordered_op :>=
      when :EQ
        do_ordered_op :==
      when :NE
        # we want to make sure all of the values are unique
        list = []
        n = @stack.pop
        list = @stack.pop(n).uniq
        @stack.push list.length == n
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
        bits = name.split(/:/)
        bits = [ bits.first, bits.drop(1).map{ |bit|
          if bit.start_with?('$')
            @vars[bit[1..-1]]
          else
            bit
          end
        }.flatten.join(':') ]
        if PROPERTY_TYPES.include?(bits.first)
          @objects[:this].send("set_" + bits.first, bits.last, value, @objects)
          if @objects[:this].respond_to?(:"save!")
            @objects[:this].save!
          end
        end
      when :GET_THIS_PROP
        name = @stack.pop
        bits = name.split(/:/)
        if bits.length == 1
          @stack.push @objects[bits.first.to_sym]
        elsif @objects[:this].present? && PROPERTY_TYPES.include?(bits.first)
          bits = [ bits.first, bits.drop(1).map{ |bit|
            if bit.start_with?('$')
              @vars[bit[1..-1]]
            else
              bit
            end
          }.flatten.join(':') ]
          @stack.push @objects[:this].send(bits.first, bits.last, @objects)
        else
          @stack.push nil
        end
      when :REMOVE_PROP
        name = @stack.pop
        bits = name.split(/:/)
        if PROPERTY_TYPES.include?(bits.first)
          bits = [ bits.first, bits.drop(1).map{ |bit|
            if bit.start_with?('$')
              @vars[bit[1..-1]]
            else
              bit
            end
          }.flatten.join(':') ]
          @objects[:this].send("reset_" + bits.first, bits.last, @objects)
          if @objects[:this].respond_to?(:"save!")
            @objects[:this].save!
          end
        end
      ##
      # GET_THIS_BASE_PROP
      #
      # Retrieves the value of the property without any intervening calculations
      #
      when :GET_THIS_BASE_PROP
        name = @stack.pop
        bits = name.split(/:/)
        if PROPERTY_TYPES.include?(bits.first)
          bits = [ bits.first, bits.drop(1).map{ |bit|
            if bit.start_with?('$')
              @vars[bit[1..-1]]
            else
              bit
            end
          }.flatten.join(':') ]
          @stack.push @objects[:this].send("get_" + bits.first, bits.last, @objects)
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
        if @objects.include?(name.to_sym)
          @stack.push @objects[name.to_sym]
        else
          @stack.push nil
        end
      when :GET_VAR
        name = @stack.pop
        @stack.push @vars[name]
      when :GET_PROP
        name = @stack.pop
        obj = @stack.pop
        bits = name.split(/:/)
        if bits.length == 1
          @stack.push @objects[bits.first.to_sym]
        elsif PROPERTY_TYPES.include?(bits.first)
          bits = [ bits.first, bits.drop(1).map{ |bit|
            if bit.start_with?('$')
              @vars[bit[1..-1]]
            else
              bit
            end
          }.flatten.join(':') ]
          if obj.is_a?(Array)
            @stack.push obj.collect{|o| o.send(bits.first, bits.last, @objects) }.flatten
          elsif obj.nil?
            @stack.push nil
          else
            @stack.push obj.send(bits.first, bits.last, @objects)
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
        puts "unknown opcode at #{@ip-1}: #{code}"
        until @code[@ip].nil? || @code[@ip].is_a?(Symbol)
          @ip += 1
        end
      end
    end

  private

    def game
      SecondContract::Game.instance
    end

    def do_series_op init, op
      n = @stack.pop
      if n > 0
        case init
        when String
          @stack.push @stack.pop(n).flatten.compact.inject("", op)
        when true, false
          case op
          when :and
            @stack.push @stack.pop(n).flatten.all? { |i| i }
          when :or
            @stack.push @stack.pop(n).flatten.any? { |i| i }
          else
            @stack.pop(n)
            @stack.push false
          end
        else
          if @stack.last.is_a?(Fixnum)
            @stack.push @stack.pop(n).compact.inject(init.to_i, op)
          else
            @stack.push @stack.pop(n).compact.inject(init.to_f, op)
          end
        end
      else
        @stack.push init
      end
    end

    def do_ordered_op op
      n = @stack.pop
      list = @stack.pop(n)
      if list.include?(nil)
        @stack.push false
      else
        @stack.push list.zip(list.drop(1)).all?{ |p| p.last.nil? || p.first.send(op, p.last) || (Array(p.first)&Array(p.last)).length > 0}
      end
    end
  end
end