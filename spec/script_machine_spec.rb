$: << 'lib'

require 'rspec'
require 'yaml'

require 'active_record'
require 'second-contract/game'
require 'second-contract/machine/script'
require 'second-contract/model/archetype'

describe SecondContract::Machine::Script do
  before :each do
    @object = Archetype.new({})
  end

  describe "#new" do
    it "takes no parameters and returns a Script parsing object" do
      @parser = SecondContract::Machine::Script.new([ :PUSH, 1 ])
      @parser.should be_an_instance_of SecondContract::Machine::Script
    end
  end

  describe "#run" do
    it "runs a supplied compilation" do
      @parser = SecondContract::Machine::Script.new([ :PUSH, 1 ])
      res = @parser.run({this: @object})
      res.should eq 1
    end

    it "should return a simple constant when pushing a single value on the stack" do
      @machine = SecondContract::Machine::Script.new([
        :PUSH, 123
      ])
      @machine.run({}).should eq 123
    end

    it "should return a sum of values" do
      @machine = SecondContract::Machine::Script.new([
        :PUSH, 123,
        :PUSH, 234,
        :PUSH, 345,
        :PUSH, 3,
        :SUM
      ])
      @machine.run({}).should eq (123+234+345)
    end

    it "adds three numbers together" do
      @parser = SecondContract::Machine::Script.new([
        :PUSH, 1, :PUSH, 2, :PUSH, 3, 
        :PUSH, 3, :SUM
      ])

      res = @parser.run({this: @object})
      res.should eq 6
    end

    it "multiplies three numbers together" do
      @parser = SecondContract::Machine::Script.new([
        :PUSH, 2, :PUSH, 4, :PUSH, 6, 
        :PUSH, 3, :PRODUCT
      ])

      res = @parser.run({this: @object})
      res.should eq 48
    end

    it "adds three numbers together multiple times" do
      @parser = SecondContract::Machine::Script.new([
        :PUSH, 1, :PUSH, 2, :PUSH, 3, 
        :PUSH, 3, :SUM
      ])

      res = @parser.run({this: @object})
      res.should eq 6
      res = @parser.run({this: @object})
      res.should eq 6
    end

    it "stores and retrieves variables" do
      @parser = SecondContract::Machine::Script.new([
        :PUSH, 3.14, :PUSH, "foo", :SET_VAR, 
        :PUSH, "foo", :GET_VAR 
      ])

      res = @parser.run({this: @object})
      res.should eq 3.14
    end

    it "stores and retrieves properties" do
      @parser = SecondContract::Machine::Script.new([
        :PUSH, 3, :PUSH, "trait:flaming", :SET_THIS_PROP,
        :PUSH, "trait:flaming", :GET_THIS_PROP
      ])

      res = @parser.run({this: @object})
      res.should eq 3
      @object.trait("flaming").should eq 3
    end
  end
end