require 'second-contract/parser/mudmode'

describe MudMode do
  subject(:parser) { MudMode.new }

  describe "#new" do
    it "takes no parameters and returns a MudMode object" do
      expect(parser).to be_an_instance_of MudMode
    end
  end

  describe "#to_mudmode" do
    def expect_serialization_of(arg)
      expect(parser.to_mudmode(arg))
    end

    it "takes an integer and returns a string representation" do
      expect_serialization_of(10).to eq "10"
    end

    it "takes a float and returns a string representation" do
      expect_serialization_of(1.23).to eq "1.23"
    end

    it "takes a string and returns a string with proper escaped quotes" do
      expect_serialization_of('this has a "quote".').to eq "\"this has a \\\"quote\\\".\""
    end

    it "takes a string and removes any non-newline and non-tab escape characters" do
      expect_serialization_of("This\t1\x0f2 3\n4").to eq "\"This\\t12 3\\n4\""
    end

    it "takes a list of numbers and returns an encoded array" do
      expect_serialization_of([1, 2, 3]).to eq "({1,2,3})"
    end

    it "takes a list of lists and returns a nested encoded array" do
      expect_serialization_of([1,[2,3],4,[5,[6,7]]]).to eq "({1,({2,3}),4,({5,({6,7})})})"
    end

    it "takes a hash and returns an encoded hash" do
      expect_serialization_of({ 'foo' => 3, 'bar' => 10}).to eq "([\"bar\":10,\"foo\":3])"
    end
  end

  describe "#parse" do
    def expect_parse_of(arg)
      expect(parser.parse(arg))
    end

    it "takes an encoded integer and returns an Fixnum object" do
      expect_parse_of("10").to be_an_instance_of Fixnum
      expect_parse_of("10").to eq 10
    end

    it "takes an encoded list of integers and returns an Array of Integer" do
      expect_parse_of("({1,3,5,7,11})").to eq [1,3,5,7,11]
    end

    it "takes an encoded list of lists of integers and returns the proper Ruby objects" do
      expect_parse_of("({1,({3,5}),7,({({11})})})").to eq [1,[3,5],7,[[11]]]
    end

    it "takes an encoded empty array and returns an empty Array object" do
      expect_parse_of("({})").to eq []
    end

    it "takes an encoded empty hash and returns an empty Hash object" do
      expect_parse_of("([])").to eq ({})
    end

    it "takes an encoded hash and returns a proper Ruby Hash" do
      expect_parse_of("([\"foo\":3])").to eq ({ 'foo' => 3 })
    end

    it "takes an encoded float and returns a Ruby Float object" do
      expect_parse_of("1.23").to be_an_instance_of Float
      expect_parse_of("1.23").to eq 1.23
    end
  end
end