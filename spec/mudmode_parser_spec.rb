$: << 'lib'

require 'rspec'

require 'active_record'
require 'second-contract/parser/mudmode'

describe SecondContract::Parser::MudMode do
  before :each do
    @parser = SecondContract::Parser::MudMode.new
  end

  describe "#new" do
    it "takes no parameters and returns a MudMode object" do
      @parser.should be_an_instance_of SecondContract::Parser::MudMode
    end
  end

  describe "#to_mudmode" do
    it "takes an integer and returns a string representation" do
      @parser.to_mudmode(10).should eq "10"
    end

    it "takes a float and returns a string representation" do
      @parser.to_mudmode(1.23).should eq "1.23"
    end

    it "takes a string and returns a string with proper escaped quotes" do
      @parser.to_mudmode('this has a "quote".').should eq "\"this has a \\\"quote\\\".\""
    end

    it "takes a string and removes any non-newline and non-tab escape characters" do
      @parser.to_mudmode("This\t1\x0f2 3\n4").should eq "\"This\\t12 3\\n4\""
    end

    it "takes a list of numbers and returns an encoded array" do
      @parser.to_mudmode([1, 2, 3]).should eq "({1,2,3})"
    end

    it "takes a list of lists and returns a nested encoded array" do
      @parser.to_mudmode([1,[2,3],4,[5,[6,7]]]).should eq "({1,({2,3}),4,({5,({6,7})})})"
    end

    it "takes a hash and returns an encoded hash" do
      @parser.to_mudmode({ 'foo' => 3, 'bar' => 10}).should eq "([\"bar\":10,\"foo\":3])"
    end
  end

  describe "#parse" do
    it "takes an encoded integer and returns an Fixnum object" do
      int = @parser.parse("10")
      int.should be_an_instance_of Fixnum
      int.should eq 10
    end

    it "takes an encoded list of integers and returns an Array of Integer" do
      @parser.parse("({1,3,5,7,11})").should eq [1,3,5,7,11]
    end

    it "takes an encoded list of lists of integers and returns the proper Ruby objects" do
      @parser.parse("({1,({3,5}),7,({({11})})})").should eq [1,[3,5],7,[[11]]]
    end

    it "takes an encoded empty array and returns an empty Array object" do
      @parser.parse("({})").should eq []
    end

    it "takes an encoded empty hash and returns an empty Hash object" do
      @parser.parse("([])").should eq ({})
    end

    it "takes an encoded hash and returns a proper Ruby Hash" do
      @parser.parse("([\"foo\":3])").should eq ({ 'foo' => 3 })
    end

    it "takes an encoded float and returns a Ruby Float object" do
      float = @parser.parse("1.23")
      float.should be_an_instance_of Float
      float.should eq 1.23
    end
  end
end