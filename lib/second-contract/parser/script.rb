module SecondContract::Parser
end

class SecondContract::Parser::Script
  require 'yaml'

  def initialize 
    @binops = {
      :DEFAULT => [ "//", 10, :left ],
      :MPY     => [ "*",   4, :left ],
      :DIV     => [ "/",   4, :left ],
      :MOD     => [ "%",   4, :left ],
      :PLUS    => [ "+",   3, :left ],
      :MINUS   => [ "-",   3, :left ],
      :LT      => [ "<",   2, :left ],
      :LE      => [ "<=",  2, :left ],
      :EQ      => [ "=",   2, :left ],
      :GE      => [ ">=",  2, :left ],
      :GT      => [ ">",   2, :left ],
      :NE      => [ "<>",  2, :left ],
      :AND     => [ "and", 1, :left ],
      :OR      => [ "or",  0, :left ],
      :NEAR    => [ "near", 2, :left ],
      :UNDER   => [ "under", 2, :left ],
      :IN      => [ "in", 2, :left ],
      :ABOVE   => [ "above", 2, :left ],
      :ON      => [ "on", 2, :left ],
    }

    @binop_nary = [ :PLUS, :MINUS, :MPY, :DIV, :MOD, :AND, :OR, :DEFAULT ]

    @binop_code = @binops.keys.inject({}) { |h, k| h[@binops[k][0]] = k; h }
    
    @functions = %w(performs)

    @binop_regex = Regexp.new(
      "(" +
        @binops.keys.sort { |a,b| 
          @binops[b][0].length - @binops[a][0].length 
        }.map{ |a| 
          a = @binops[a][0].gsub(/[*.?()+{}\[\]\|]/) {|m| "\\#{m}"}
          a.match(/[a-zA-Z]$/) ? a+"\\b" : a
        }.join("|") +
      ")"
    )

    @function_regex = Regexp.new(
      "(" +
        @functions.sort { |a,b|
          b.length - a.length
        }.join("|") +
      ")\\b"
    )
  end

  ##
  #
  # :call-seq:
  #   parser.errors? -> true | false
  #
  # Returns +true+ if there were errors in parsing and +false+ otherwise.
  #
  def errors?
    @errors.length == 0
  end

  ##
  #
  # :call-seq:
  #   parser.errors -> Array
  #
  # Each error in the array is a Hash with the following keys:
  #
  # [line] Source line number at the time the error was detected
  # [col] Column within the line at the time the error was detected
  # [msg] A string describing the detected error
  # [src] The text of the source line
  #
  def errors
    @errors
  end

  def parse_archetype source
    setup source

    parse_allowing 'archetype', :traits, :qualities, :abilities, :calculations, :data, :archetype, :finally, :reactions
  end

  def parse_trait source
    setup source

    parse_allowing 'trait', :traits, :qualities, :abilities, :calculations, :finally, :reactions
  end

  def parse_verb source
    # we expect a header YAML section followed by markdown help text
    parts = ("\n" + source + "\n").split(/\n---\n/).drop(1)
    # parts[0] == YAML
    # parts[1...] = markdown
    yaml = YAML.load(parts.shift)
    yaml[:help] = parts.join("\n---\n")
    yaml
  end

  def parse_adverb source
    parse_verb source
  end

private

  def parse_allowing item_type, *parts
    # at the head of the archetype definition, we can have mixins, then value declarations
    mixin_list = []
    abilities = []
    qualities = []
    calculations = []
    reactions = []
    data = {}
    ur_name = nil
    finally = nil

    if @scanner.scan(/---\n/)
      # the rest is YAML until we get to \n---\n
      body = @scanner.scan_until(/\n---\n/)
      if body.nil?
        body = @scanner.rest
        @scanner.terminate
      end
      yaml = YAML.load(body.sub(/\s*---\s*$/, ''))
      hashKeys = yaml.keys.select{|k| yaml[k].is_a?(Hash)}
      while hashKeys.count > 0
        hashKeys.each do |parent|
          yaml[parent].each do |k,v|
            yaml[parent + ":" + k] = v
          end
          yaml.delete parent
        end
        hashKeys = yaml.keys.select{|k| yaml[k].is_a?(Hash)}
      end
      yaml.each do |k,v|
        yaml[k] = [ :DATA, v ]
      end
      data = yaml
    end

    while !@scanner.eos?
      _skip_all_space
      case
      when @scanner.scan(/is\b/)
        _skip_space
        if !parts.include?(:traits) || @scanner.match?(/[^,\n]+?[ \t\f\r](if|unless)\b/)
          if parts.include?(:qualities)
            qualities << parse_quality
          else
            error("Qualities are not allowed in #{item_type} definitions", /[\n;]/)
          end
        elsif parts.include?(:traits)
          mixin_list += parse_mixins
        else
          error("Traits are not allowed in #{item_type} definitions", /[\n;]/)
        end
      when @scanner.scan(/based\s+on\b/)
        _skip_space
        if parts.include?(:archetype)
          if ur_name
            error("Archetype base is already defined", /[\n;]/)
          else
            ur_name = _nc_name
            if ur_name.nil?
              error("#{item_type.capitalize} is noted as based on another archetype, but no archetype is named", /[\n;]/)
            end
          end
        else
          error("Archetypes are not allowed in #{item_type} definitions", /[\n;]/)
        end
      when @scanner.scan(/calculates\b/)
        _keep_named_expression :parse_calculation, "Calculations", calculations, parts.include?(:calculations)
      when @scanner.scan(/reacts\s+to\b/)
        _keep_named_expression :parse_reaction, "Reactions", reactions, parts.include?(:reactions)
      when @scanner.scan(/validates\b/)
        _keep_named_expression :parse_validator, "Validators", validators, parts.include?(:validators)
      when @scanner.scan(/can\b/)
        _keep_named_expression :parse_ability, "Abilities", abilities, parts.include?(:abilities)
      else
        name = _nc_name
        if @scanner.scan(/starts\s+as\b/)
          _skip_all_space
          if parts.include?(:data)
            data[name] = parse_expression
          else
            parse_expression
            error("Data is not allowed in #{item_type} definitions")
          end
        else
          error("Unable to parse directive (#{name})", /[\n;]/)
        end
      end
      _skip_all_space
    end

    info = {}
    info[:archetype] = ur_name if parts.include?(:archetype)
    info[:traits] = mixin_list if parts.include?(:traits)
    info[:abilities] = Hash[abilities.compact] if parts.include?(:abilities)
    info[:qualities] = Hash[qualities.compact] if parts.include?(:qualities)
    info[:data] = data if parts.include?(:data)
    info[:calculations] = Hash[calculations.compact] if parts.include?(:calculations)
    info[:reactions] = Hash[reactions.compact] if parts.include?(:reactions)
    info[:finally] = finally if parts.include?(:finally)
    info
  end

  def setup str
    @scanner = StringScanner.new str
    @bols = [ 0 ]
    pos = 0
    while pos = str.index("\n", pos)
      @bols << pos
      pos += 1
    end
    @bols << str.length
    @tokens = []
    @errors = []
     _skip_all_space
  end

  def current_line
    pos = @scanner.pos
    bol = @bols.bsearch { |x| x > pos }
    @bols.index(bol)
  end

  def current_column
    pos = @scanner.pos
    bol = @bols.bsearch { |x| x > pos }
    idx = @bols.index(bol)
    if idx.nil?
      1
    else
      bol = @bols[idx-1]
      pos - bol + 1
    end
  end

  def error msg, regex = nil
    cl = current_line
    if cl.nil?
      src = @scanner.string[@bols.last .. @scanner.string.length-1]
    else
      src = @scanner.string[@bols[cl-1] .. @bols[cl]-1]
    end
    @errors << {
      line: cl,
      col: current_column,
      msg: msg,
      src: src + "\n" + (" "*(current_column-1)) + "^"
    }
    if !regex.nil?
      @scanner.skip_until(regex)
      _skip_space
    end
  end

  def _scan_token regex
    if @scanner.scan(regex)
      match = @scanner[1]
      _skip_space
      match
    else
      nil
    end
  end

  def _nc_name
    _scan_token(/([a-z][-a-z_A-Z0-9]*(:[a-z][-a-z_A-Z0-9]*)*)/)
  end

  def _var_name
    _scan_token(/\$([a-zA-Z][-a-zA-Z0-9_]*)/)
  end

  def _skip_space
    @scanner.skip(/[ \t\r\f]+/) if !@scanner.eos?
  end

  def _skip_all_space
    @scanner.skip(/(\s*(#[^\n]*\n)?)+/) if !@scanner.eos?
  end

  def _at_eos? sep = /;/
    pat = /[\n]|#{sep}/
    _skip_space
    if @scanner.eos? || @scanner.match?(pat) || @scanner.match?(/\#[^\n]*\n/)
      true
    else
      false
    end
  end

  def _expect_eos sep = /;/
    pat = /[\n]|#{sep}/
    _skip_space
    if !(@scanner.eos? || @scanner.scan(pat) || @scanner.scan(/\#[^\n]*\n/))
      # error - expected newline or semicolon (or whatever sep is set to)
      error("Expected new line or expression separator", pat)
    end
    _skip_all_space
  end

  def parse_dictionary ending = /\}\)/
    # pairs: key: exp
    dict = {}
    _skip_all_space
    while !@scanner.scan(ending)
      if @scanner.eos?
        error("End of file unexpected in dictionary definition")
        break
      end
     
      if @scanner.scan(/["']/)
        quote = @scanner[0]
        if @scanner.scan(/([^\\#{quote}]+|\\.)*/)
          key = @scanner[0]
          if @scanner.eos? || !@scanner.scan(/[#{quote}]/)
            error("End of file unexpected in quoted string")
          end
        end
      else
        key = _nc_name
      end
      if key.nil?
        error("Expected a key name", /[,\n]/)
        next
      end
      if !@scanner.scan(/:/)
        error("Expected a ':' separating the key from the value", /[,\n]/)
        _skip_all_space
        next
      end
      _skip_all_space
      value = parse_expression
      _expect_eos ','
      if dict.include?(key)
        dict[key] << value
      else
        dict[key] = [ value ]
      end
      _skip_all_space
    end
    
    [ :HASH, dict ]
  end

  def parse_list
    list = [ ]
    _skip_all_space
    while !@scanner.scan(/\]\)/)
      if @scanner.eos?
        error("End of file unexpected in list definition")
        break
      end

      value = parse_expression
      _expect_eos ','
      list << value
      _skip_all_space
    end
    [ :LIST, list ]
  end

  def parse_arg_list
    list = []
    _skip_all_space
    while !@scanner.scan(/\)/)
      if @scanner.eos?
        error("End of file unexpected in list definition")
        break
      end

      value = parse_expression
      _expect_eos ','
      list << value
      _skip_all_space
    end
    list
  end

  def parse_if_then_else
    ret = [ :WHEN ]
    reversed = @scanner[1] == 'unless'
    _skip_space
    cond = parse_expression /then\b/
    thenExp = parse_compound_expression /(else|elsif|end)\b/
    if reversed
      if cond.first == :NOT
        cond = cond.last
      else
        cond = [ :NOT, cond ]
      end
    end
    ret << [ cond, thenExp ]
    while @scanner.matched == 'elsif'
      _skip_all_space
      cond = parse_expression /then\b/
      thenExp = parse_compound_expression /(else|elsif|end)\b/
      ret << [ cond, thenExp ]
    end
    if @scanner.matched == 'else'
      _skip_all_space
      elseExp = parse_compound_expression 'end'
    end
    _skip_space
    ret << elseExp
    ret
  end

  def parse_quoted_string delim = '"'
    @scanner.scan(/([^\\#{delim}]+|\\.)*/)
    ret = [ :STRING, @scanner[1].gsub(/\\./) {|m| 
      case m[1]
      when 'n'
        "\n"
      when 'r'
        "\r"
      when 'e'
        "\e"
      when 'f'
        "\f"
      when 't'
        "\t"
      else
        m[1]
      end 
    } ]
    if @scanner.eos? || !@scanner.scan(/#{delim}/)
      error("Unterminated string")
    end
    ret
  end

  def parse_term
    case
    when @scanner.scan(/(if|unless)\b/)
      ret = parse_if_then_else
    when @scanner.scan(/not\b/)
      _skip_all_space
      ret = parse_term
      if ret.first == :NOT
        ret = ret.last
      else
        ret = [ :NOT, ret ]
      end
    when @scanner.scan(/%w(.)/)
      l = @scanner[1]
      case l
      when '['
        r = ']'
      when '('
        r = ')'
      when '{'
        r = '}'
      when '<'
        r = '>'
      else
        r = l
      end
      @scanner.scan(/([^#{r}]*)/)
      s = @scanner[1]
      if !@scanner.scan(/#{r}/)
        error("Unterminated word list found", /[;\n]/)
      end
      ret = [ :LIST, s.split(/\s+/) ]
    when @scanner.scan(/is\b/)
      ret = _is_can_q :IS
    when @scanner.scan(/can\b/)
      ret = _is_can_q :CAN
    when @scanner.scan(/\(\{/)
      ret = parse_dictionary
    when @scanner.scan(/\(\[/)
      ret = parse_list
    when @scanner.scan(/\(/)
      _skip_all_space
      ret = parse_expression /\)/
    when @scanner.scan(/\{/)
      _skip_all_space
      ret = parse_compound_expression /\}/
    when @scanner.scan(/do\b/)
      _skip_all_space
      ret = parse_compound_expression /end\b/
    when @scanner.scan(/([-+]?\d*\.\d+)/)
      ret = [ :FLOAT, @scanner[1].to_f ]
    when @scanner.scan(/([-+]?\d+\.)/)
      ret = [ :FLOAT, @scanner[1].to_f ]
    when @scanner.scan(/([-+]?\d+)/)
      ret = [ :INT, @scanner[1].to_i ]
    when @scanner.scan(/([-+])\(/)
      sign = @scanner[1]
      _skip_all_space
      ret = parse_expression /\)/
      if sign == '-'
        ret = [ :NEGATE, ret ]
      end
    when @scanner.scan(/["']/)
      ret = parse_quoted_string @scanner[0]
    when @scanner.scan(/[A-Z][-a-z0-9A-Z]*/)
      ret = [ :CONST, @scanner[0] ]
      _skip_space
      if @scanner.scan(/\(/)
        _skip_all_space
        ret.first = :FUNCTION
        ret.concat parse_arg_list
      end
    when @scanner.scan(/is\b/)
      _skip_all_space
      match = _nc_name
      if match.nil?
        error("Expected a quality for 'is'")
      else
        ret = [ :IS, match ]
      end
    when @scanner.scan(/can\b/)
      match = _nc_name
      if match.nil?
        error("Expected an ability name for 'can'")
      else
        pos = _can_as_pos
        ret = [ :CAN, pos.to_sym, match ]
      end
    when (match = _var_name)
      ret = [ :VAR, match ]
    end
    if ret.nil? && (match = _nc_name)
      ret = [ :PROP, match ]
    end
    if ret.nil?
      error("Expected a dictionary, list, number, string, constant, variable, or expression")
    end
    _skip_space
    if @scanner.match?(/[\[\.]/)
      ret = [ :INDEX, ret ]
    end
    while @scanner.scan(/[\[\.]/)
      # selecting a member of a list
      if @scanner[0] == '['
        index = parse_expression /\]/
      else
        index = _nc_name
      end
      ret << index
      _skip_space
    end
    ret
  end

  ##
  # If the operator can take arbitrary number of arguments, then we
  # collapse them into a single list. Otherwise, we keep the tree
  # intact.
  #
  def collapse_expression exp
    op = exp.first
    if @binop_nary.include?(op)
      ret = [ op ]
      exp.drop(1).each do |x|
        if x.first == op
          ret.concat x.drop(1)
        else
          ret.push x
        end
      end
      ret
    else
      exp
    end
  end

  def parse_expression sep = nil
    # if expect is nil, then we just build until we get to something that doesn't fit
    if !sep.nil?
      expect = /\s*#{sep}/
    end
    # we always start with a term
    terms = []
    ops = []
    term = parse_term
    if term.nil? # no term!
      if !expect.nil?
        error("Expected a term", expect)
        _skip_space
      end
      return nil
    else
      terms << term
    end

    # next stuff determines what we do - operator or something else?
    # we want to pull terms and operators out of the stream and then
    # organize them according to precedence
    while (expect.nil? || !@scanner.scan(sep)) && (@scanner.scan(@binop_regex) || @scanner.scan(@function_regex))
      op = @binop_code[fctn = @scanner[0].strip]
      if op.nil?
        # we're calling a function with the previous term as the primary object
        args = parse_function_args(fctn)
        obj = terms.pop
        terms << [ :METHOD, obj, fctn ].concat(args)
      else
        ops << @binop_code[@scanner[0].strip]
        _skip_all_space
        term = parse_term
        if term.nil?
          error("Expected a term following '#{ops.last}'")
          if !expect.nil?
            @scanner.skip_until(expect)
            _skip_space
          end
          break
        else
          terms << term
        end
        _skip_space
      end
      if !expect.nil?
        _skip_all_space
        if !@scanner.scan(expect)
          error("Expected #{sep}")
        end
      end
    end

    if terms.length == 1
      return terms.first
    elsif terms.length == 2
      return [ ops.first, terms.first, terms.last ]
    end

    op_stack = []
    val_stack = []
    while !ops.empty?
      val_stack.push terms.shift
      op = ops.shift
      if op_stack.empty? || operator_precedence(op) > operator_precedence(op_stack.last)
        op_stack.push op
      elsif operator_precedence(op) == operator_precedence(op_stack.last)
        combine_top_vals val_stack, op
      else
        while !op_stack.empty? && operator_precedence(op_stack.last) >= operator_precedence(op)
          combine_top_vals val_stack, op, op_stack.pop
        end
        op_stack.push op
      end
    end
    val_stack.push terms.shift

    while !op_stack.empty?
      combine_top_vals val_stack, op_stack.pop
    end
    val_stack.pop
  end

  def parse_compound_expression ending
    expect = /#{ending}\b/
    _skip_all_space
    expressions = []

    while !@scanner.scan(expect)
      if @scanner.eos?
        error("Missing '#{ending}' for compound expression")
        break
      end
      case
      when @scanner.scan(/\$([a-zA-Z][-a-zA-Z0-9_]*)\s+starts\s+as\b/)
        var_name = @scanner[1]
        _skip_all_space
        expressions << [ :SET, [ :VAR, var_name ], parse_expression ]
      when @scanner.scan(/uhoh\b/)
        _skip_space
        expressions << [ :UHOH, parse_term ]
      when @scanner.scan(/\[/)
        _skip_all_space
      when @scanner.scan(/(sight|sound|cold|heat|vibration)?:(["'(])/)
        expressions << parse_sensation(@scanner[2], @scanner[1])
      when @scanner.scan(/set\b/)
        _skip_all_space
        if var = _var_name
          op = :SET_VAR
          _skip_space
        else
          op = :SET_PROP
          var = _nc_name
        end
        if @scanner.scan(/to\b/)
          _skip_all_space
          expressions << [ op, var, parse_expression ]
        else
          expressions << [ op, var, [ :CONST, 'True' ] ]
        end
      when @scanner.scan(/unset\b/)
        _skip_all_space
        if var = _var_name
          op = :UNSET_VAR
          _skip_space
        else
          op = :UNSET_PROP
          var = _nc_name
        end
        expressions << [ op, var ]
      else
        expressions << parse_expression
      end
      _expect_eos
    end

    [ :COMPOUND_EXP, expressions ]
  end



  def parse_mixins
    mixins = []

    match = _nc_name
    if match
      mixins << match
      while @scanner.scan(/(,\s*)+/)
        _skip_all_space
        match = _nc_name
        if match
          mixins << match
        else
          # error
          error("Expected a trait name", /,/)
        end
      end
      #@scanner.skip(/[ \t]*/)
      _expect_eos
    else
      error("Expected a trait name", /[\n;]/)
    end
    _skip_all_space

    mixins
  end

  def parse_ability
    reversed = false
    if @scanner.scan(/not\b/)
      reversed = true
      _skip_all_space
    end
    name = _nc_name
    pos = _can_as_pos
    
    if @scanner.scan(/(if|when|unless)\b/)
      _skip_all_space
      if @scanner[1] == "unless"
        reversed = !reversed
      end
      exp = parse_expression
      if reversed
        exp = [ :NOT, exp ]
      end
    else
      _expect_eos
      exp = [ :CONST, reversed ? 'False' : 'True' ]
    end
    [ name + ":" + pos, exp ]
  end

  def parse_quality
    name = _nc_name
    if @scanner.scan(/(if|when)\b/)
      _skip_all_space
      exp = parse_expression
    else
      _expect_eos
      exp = [ :EXP, [ [ :CONST, 'True' ] ] ]
    end
    [ name, exp ]
  end

  def parse_calculation
    name = _nc_name
    if @scanner.scan(/with\b/)
      _skip_all_space
      exp = parse_expression
      [ name, exp ]
    else
      error("Calculation of '#{name}' requires an expression", /[\n;]/)
      nil
    end
  end

  def _can_as_pos
    role = "any"
    if @scanner.scan(/as\b/)
      _skip_all_space
      if @scanner.scan(/(direct|indirect|agent|instrument|environment|observer)\b/)
        role = @scanner[1]
        _skip_space
      else
        error("Expected one of direct, indirect, agent, instrument, environment, or observer following 'as'", /[\n;]/)
      end
    end
    role
  end

  def parse_reaction
    name = _nc_name
    name << "-" << _can_as_pos
    if @scanner.scan(/with\b/)
      _skip_all_space
      exp = parse_expression
      [ name, exp ]
    else
      error("Expected 'with' after reaction name", /[\n;]/)
      nil
    end
  end

  def combine_top_vals val_stack, op, sop = nil
    sop = op if sop.nil?
    val = val_stack.pop
    val2 = val_stack.pop
    if val2.first == op
      if val.first == op
        val = val2 + val.drop(1)
      else
        val = val2 + [ val ]
      end
    elsif val.first == op
      val = [ val.first, val2 ] + val.drop(1)
    else
      val = [ sop, val2, val ]
    end
    val_stack.push collapse_expression val
  end

  def operator_precedence op
    case op
    when String
      @binops[@binop_code[op]][1]
    when Symbol
      @binops[op][1]
    else
      -1
    end
  end

  def _keep_named_expression parse_method, name, store, keep
    _skip_space
    calc = send(parse_method)
    if keep
      store << calc
    else
      error("#{name} are not allowed in #{item_type} definitions", /[\n;]/)
    end
  end

  def _is_can_q op
    _skip_all_space
    if @scanner.scan(/not\b/)
      reversed = true
      _skip_all_space
    else
      reversed = false
    end
    name = _nc_name
    ret = [ op, name ]
    if reversed
      ret = [ :NOT, ret ]
    end
    ret
  end

  def parse_function_args fname
    case fname
    when "performs"
      # something performs $skill with $expression vs $expression
      _skip_space
      skill = @scanner.scan(/[a-z]+/)
      if skill.nil?
        error("Expected a skill name after 'performs'")
      end
      _skip_space
      if !@scanner.scan(/with\b/)
        error("Expected 'performs ... with ...'")
      end
      _skip_all_space
      pro = parse_expression(/vs\b/)
      _skip_all_space
      con = parse_expression(/[;\n)]/)
      _skip_space
      [ skill, pro, con ]
    else
      error("Unknown method call '#{fname}'")
      []
    end
  end

  def parse_sensation delim, type = 'seen'
    if delim == '('
      content = parse_expression /\)/
    else
      content = parse_quoted_string delim
    end
    type = 'sight' unless type
    base_volume = :spoken
    volume_adjust = [ :INT, 0 ]
    if @scanner.scan(/@/)
      if @scanner.scan(/(env|whisper|spoken|shout|yell|scream)\b/)
        base_volume = @scanner[1]
        if @scanner.scan(/([-+]\d+)/)
          volume_adjust = [ :INT, @scanner[1].to_i ]
        elsif @scanner.scan(/([-+])\(/)
          sign = @scanner[1]
          _skip_all_space
          volume_adjust = parse_expression /\)/
          if sign == '-'
            volume_adjust = [ :NEGATE, volume_adjust ]
          end
        end
      else
        error("Expected one of env, whisper, spoken, shout, yell, scream following '@'", /[;\n]/)
      end
    end
    _skip_space
    [ :SENSATION, type.to_sym, base_volume.to_sym, volume_adjust, content ]
  end

  # Sensation:
  #
  #  :"..." -> simply output as-is
  #  /sight|sound|heat|cold|vibration/:"..."@/env|whisper|spoken|shout|yell|scream/[+-]?\d+ (intensity)
  #
  # sensations: sensation (',' sensation)*
  # sensation set: (* _sensations_ *)
  # sensation chain: set1 -> set2 -> ...
  #
end
