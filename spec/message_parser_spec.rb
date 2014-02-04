$: << 'lib'

require 'rspec'

require 'active_record'
require 'second-contract/parser/message'

describe SecondContract::Parser::Message do
  before :each do
    @parser = SecondContract::Parser::Message.new
  end

  describe "#new" do
    it "takes no parameters and returns a Message object" do
      @parser.should be_an_instance_of SecondContract::Parser::Message
    end
  end

  describe "parse" do
    it "takes a string of words and returns an array of strings" do
      bits = @parser.parse("This and that, over there, and the other.")
      bits.length.should eq 1
      bits.first.should eq "This and that, over there, and the other."
    end

    it "takes a string with pos tags and returns an array" do
      bits = @parser.parse("<this> looks at that.")
      @parser.errors?.should eq false
      bits.length.should eq 2
    end

    it "takes a string with pos tags for actor and this" do
      bits = @parser.parse("<actor> <looks> at <actor:possessive> <this>.")
      @parser.errors?.should eq false
      bits.length.should eq 8
    end
  end
end