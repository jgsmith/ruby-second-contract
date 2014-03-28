module SecondContract::Compiler
end

class SecondContract::Compiler::Script
  def initialize
  end

  def compile parse_tree
    @code = []
    @line = 0
    @column = 0
    @filename = '<unknown>'
    _compile(parse_tree)
    @code
  end

private

  def _compile(parse_tree)
    return if parse_tree.nil? || parse_tree.empty?
    case parse_tree.first
    when :LINE
      @line = parse_tree.last
    when :COLUMN
      @column = parse_tree.last
    when :FILENAME
      @filename = parse_tree.last
    when :COMPOUND_EXP
      @code << :MARK
      parse_tree.drop(1).each do |x|
        @code << :CLEAR
        @code << :MARK
        _compile(x)
      end
    when :LIST
      parse_tree.drop(1).reverse.each do |p|
        _compile(p)
      end
      _push parse_tree.length - 1
      @code << :MAKE_LIST
    when :DATA, :INT, :FLOAT, :STRING, :UNITS
      _push parse_tree[1]
    when :CONST
      _push SecondContract::Game.instance.constants[parse_tree[1]]
    when :SET_PROP
      compile_simple_set :SET_THIS_PROP, parse_tree
    when :SET_VAR
      compile_simple_set :SET_VAR, parse_tree
    when :UNSET_PROP
      _push parse_tree[1]
      @code << :REMOVE_PROP
    when :UNSET_VAR
      _push parse_tree[1]
      @code << :REMOVE_VAR
    when :VAR
      _push parse_tree[1]
      @code << :GET_VAR
    when :PROP
      if parse_tree.length == 2
        _push parse_tree[1]
        @code << :GET_THIS_PROP
      end
    when :INDEX
      _compile(parse_tree[1])
      parse_tree.drop(2).each do |p|
        if p.is_a?(Array)
          _compile(p)
          @code << :INDEX
        else
          _push p
          @code << :GET_PROP
        end
      end
    when :UNION
      compile_series :SET_UNION, parse_tree
    when :INTERSECTION
      compile_series :SET_INTERSECTION, parse_tree
    when :DIFF
      compile_diff_series :SET_UNION, :SET_DIFF, parse_tree
    when :PLUS
      compile_series :SUM, parse_tree
    when :CONCAT
      compile_series :CONCAT, parse_tree
    when :MINUS
      compile_diff_series :SUM, :DIFFERENCE, parse_tree
    when :MPY
      compile_series :PRODUCT, parse_tree
    when :DIV
      compile_diff_series :PRODUCT, :DIV, parse_tree
    when :MOD
      parse_tree.drop(1).reverse_each do |x|
        _compile(x)
      end
      (parse_tree.length-2).times do
        @code << :MOD
      end
    when :AND
      compile_series :AND, parse_tree
    when :OR
      compile_series :OR, parse_tree
    when :NOT
      _compile(parse_tree.last)
      @code << :NOT
    when :CAN
      _push parse_tree[1]
      @code << :THIS_CAN
    when :UHOH
      _compile parse_tree[1]
      @code << :UHOH
    when :IS
      _push parse_tree[1]
      @code << :THIS_IS
    when :FUNCTION
      parse_tree.drop(2).reverse_each do |x|
        _compile(x)
      end
      @code << :CALL
      @code << parse_tree[1]
      @code << (parse_tree.length-2)
    when :LT
      # this makes sure the items are ordered from lowest to highest
      compile_series :LT, parse_tree
    when :GT
      compile_series :GT, parse_tree
    when :NE
      # make sure all items are different
      compile_series :NE, parse_tree
    when :EQ
      compile_series :EQ, parse_tree
    when :LE
      compile_series :LE, parse_tree
    when :GE
      compile_series :GE, parse_tree
    when :SENSATION
      _compile(parse_tree[4])
      _compile(parse_tree[3])
      _push parse_tree[2]
      _push parse_tree[1]
      @code << :SENSATION
    when :DEFAULT
      _compile(parse_tree[1])
      @code << :DUP
      _push nil
      _push 2
      @code << :EQ
      loc = _jump_unless
      _drop
      _compile(parse_tree[2])
      _jump_from(loc)
    when :WHEN
      # each part is [ cond, code ] except last, which is code (if else) or nil
      jump_locs = []
      parse_tree[1..parse_tree.length-2].each do |it|
        _compile(it.first)
        loc = _jump_unless
        _compile(it.last)
        jump_locs << _jump
        _jump_from(loc)
      end
      if !parse_tree.last.nil? && !parse_tree.last.empty?
        _compile(parse_tree.last)
      end
      jump_locs.each do |loc|
        _jump_from(loc)
      end
    else
      #puts parse_tree.first.to_yaml
      raise "Unknown operation (#{parse_tree.first}) at #{@filename} line #{@line} column #{@column}"
    end
  end

  def compile_series op, parse_tree
    parse_tree.drop(1).each do |x|
      _compile(x)
    end
    _push parse_tree.length-1
    @code << op
  end

  def compile_diff_series seriesOp, diffOp, parse_tree
    _compile(parse_tree[1])
    if parse_tree.length > 3
      parse_tree.drop(2).each do |x|
        _compile(x)
      end
      _push parse_tree.length-2
      @code << seriesOp
    else
      _compile(parse_tree[2])
    end
    @code << diffOp
  end

  def compile_simple_set op, parse_tree
    if parse_tree.length > 2
      _compile(parse_tree[2])
    else
      _push true
    end
    _push parse_tree[1]
    @code << op
  end

  def _push val
    @code << :PUSH
    @code << val
  end

  def _dup
    @code << :DUP
  end

  def _drop
    @code << :DROP
  end

  def _jump_unless
    @code << :JUMP_UNLESS
    @code << 0
    @code.length
  end

  def _jump
    @code << :JUMP
    @code << 0
    @code.length
  end

  def _jump_from(loc)
    @code[loc-1] = @code.length - loc
  end
end