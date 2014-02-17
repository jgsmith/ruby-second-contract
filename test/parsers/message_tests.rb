require 'second-contract/parser/message'

describe SecondContract::Parser::Message do
  subject(:parser) { SecondContract::Parser::Message.new }

  describe "#new" do
    it "takes no parameters and returns a Message object" do
      expect(parser).to be_an_instance_of SecondContract::Parser::Message
    end
  end

  describe "parse" do
    let(:parse1) { parser.parse("This and that, over there, and the other.") }
    let(:parse2) { parser.parse("<this> looks at that.") }
    let(:parse3) { parser.parse("<actor> <looks> at <actor:possessive> <this>.") }

    it "takes a string of words and returns an array of strings" do
      expect(parse1.length).to eq 1
      expect(parse1.first).to eq "This and that, over there, and the other."
    end

    it "takes a string with pos tags and returns an array" do
      expect(parse2.length).to eq 2
    end

    it "takes a string with pos tags for actor and this" do
      expect(parse3.length).to eq 8
    end
  end
end