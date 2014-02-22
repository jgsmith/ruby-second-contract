require 'second-contract/machine/script'
require 'second-contract/compiler/script'
require 'second-contract/parser/script'
require 'second-contract/model/archetype'

describe SecondContract::Machine::Script do
  subject(:archetype) { Archetype.new({}) }
  subject(:compiler)  { SecondContract::Compiler::Script.new }
  subject(:parser)    { SecondContract::Parser::Script.new   }

  def expect_this(code, objs = {})
    expect(SecondContract::Machine::Script.new(code).run(objs))
  end
  
  describe "#new" do
    subject(:machine) { SecondContract::Machine::Script.new([ :PUSH, 1 ]) }

    it "takes no parameters and returns a Script parsing object" do
      expect(machine).to be_an_instance_of SecondContract::Machine::Script
    end
  end

  describe "#run" do
    

    it "runs a supplied compilation" do
      expect_this([ :PUSH, 1 ]).to eq 1
    end

    it "should return a sum of values" do
      expect_this([
        :PUSH, 123,
        :PUSH, 234,
        :PUSH, 345,
        :PUSH, 3,
        :SUM
      ]).to eq (123+234+345)
    end

    it "adds three numbers together" do
      expect_this([
        :PUSH, 1, :PUSH, 2, :PUSH, 3, 
        :PUSH, 3, :SUM
      ]).to eq 6
    end

    it "multiplies three numbers together" do
      expect_this([
        :PUSH, 2, :PUSH, 4, :PUSH, 6, 
        :PUSH, 3, :PRODUCT
      ]).to eq 48
    end

    it "adds three numbers together multiple times" do
      @machine = SecondContract::Machine::Script.new([
        :PUSH, 1, :PUSH, 2, :PUSH, 3, 
        :PUSH, 3, :SUM
      ])

      res = @machine.run({this: @object})
      expect(res).to eq 6
      res = @machine.run({this: @object})
      expect(res).to eq 6
    end

    it "stores and retrieves variables" do
      expect_this([
        :PUSH, 3.14, :PUSH, "foo", :SET_VAR, 
        :PUSH, "foo", :GET_VAR 
      ]).to eq 3.14
    end

    it "stores and retrieves properties" do
      expect_this([
        :PUSH, 3, :PUSH, "trait:flaming", :SET_THIS_PROP,
        :PUSH, "trait:flaming", :GET_THIS_PROP
      ], {this: archetype}).to eq 3
      expect(archetype.trait("flaming")).to eq 3
    end
  end

  describe "working with the parser and compiler" do
    def compile(type, name, script)
      parse = parser.parse_archetype(script)
      compiler.compile(
        parse[type][name]
      )
    end

    it "runs a simple if-then-else statement" do
      expect_this(compile(:calculations, "trait:foo", <<'EOC')).to eq 20
calculates trait:foo with
  if 10 < 30 < 50 then
    20
  else
    40
  end
EOC
    end

    it "runs a more complex if-then-else statement" do
      expect_this(compile(:reactions, "env:msg-any", <<'EOC')).to eq 60
reacts to env:msg with
  if 20 > 40 then
    Emit("env:sight", "This shouldn't be seen.")
    30
  else
    60
  end
EOC
    end
  end
end