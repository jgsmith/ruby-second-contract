$: << 'lib'

require 'rspec'
require 'yaml'

require 'active_record'
require 'second-contract/game'
require 'second-contract/compiler/script'

describe SecondContract::Compiler::Script do
  before :each do
    @compiler = SecondContract::Compiler::Script.new
  end

  describe "#new" do
    it "takes no parameters and returns a Script parsing object" do
      @compiler.should be_an_instance_of SecondContract::Compiler::Script
    end
  end

  describe "#compile" do
    it "compiles multiplication" do
      res = @compiler.compile([
        :MPY,
        [ :INT, 6 ],
        [ :INT, 2 ]
      ])

      res.should be_an_instance_of Array
      res.should eq [ :PUSH, 6, :PUSH, 2, :PUSH, 2, :PRODUCT ]
    end
  end
end