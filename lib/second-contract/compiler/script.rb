module SecondContract::Compiler
end

class SecondContract::Compiler::Script
  def initialize
  end

  def compile parse_tree
    @code = []
    _compile(parse_tree)
    @code
  end

private

  def _compile(parse_tree)
    case parse_tree.first
    when :COMPOUND_EXP
      parse_tree.drop(1).each do |x|
        @code << :CLEAR
        _compile(x)
      end
    when :DATA, :INT, :FLOAT
      push parse_tree[1]
    when :SET_PROP
      compile_simple_set :STORE_PROP
    when :SET_VAR
      compile_simple_set :STORE_VAR
    when :UNSET_PROP
      push parse_tree[1]
      @code << :REMOVE_PROP
    when :UNSET_VAR
      push parse_tree[1]
      @code << :REMOVE_VAR
    when :VAR
      push parse_tree[1]
      @code << :FETCH_VAR
    when :PROP
      if parse_tree.length == 2
        push parse_tree[1]
        @code << :GET_THIS_PROP
      else
        push parse_tree[2]
        push parse_tree[1]
        @code << :GET_PROP
      end
    when :PLUS
      compile_series :SUM, parse_tree
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
    when :FUNCTION
      parse_tree.drop(2).reverse_each do |x|
        _compile(x)
      end
      @code << :CALL
      @code << parse_tree[1] + (parse_tree.length-2)
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
      push parse_tree[2]
      push parse_tree[1]
      @code << :SENSATION
    when :WHEN
      # each part is [ cond, code ] except last, which is code (if else) or nil
      jump_locs = []
      parse_tree[1..parse_tree.length-2].each do |it|
        _compile(it[0])
        code << :JNE
        loc = @code.length
        code << 0
        _compile(it[1])
        @code[loc] = @code.length - loc - 1
        @code << :JMP
        jump_locs << @code.length
        @code << 0
      end
      if !parse_tree.last.nil?
        _compile(parse_tree.last)
      end
      jump_locs.each do |loc|
        @code[loc] = @code.length - loc - 1
      end
    else
      raise "Unknown operation (#{parse_tree.first})"
    end
  end

  def compile_series op, parse_tree
    parse_tree.drop(1).each do |x|
      _compile(x)
    end
    @code << :PUSH
    @code << parse_tree.length-1
    @code << op
  end

  def compile_diff_series seriesOp, diffOp, parse_tree
    _compile(parse_tree[1])
    if parse_tree.length > 3
      parse_tree.drop(2).each do |x|
        _compile(x)
      end
      @code << :PUSH
      @code << parse_tree.length-2
      @code << seriesOp
    else
      _compile(parse_tree[2])
    end
    @code << diffOp
  end

  def compile_simple_set op, parse_tree
    _compile(parse_tree[2])
    @code << :PUSH
    @code << parse_tree[1]
    @code << op
  end

  def push val
    @code << :PUSH
    @code << val
  end
end