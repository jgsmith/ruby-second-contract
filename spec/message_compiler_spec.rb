$: << 'lib'

require 'rspec'

require 'active_record'
require 'second-contract/parser/message'
require 'second-contract/compiler/message'

describe SecondContract::Parser::Message do
  before :each do
    @parser = SecondContract::Parser::Message.new
    @compiler = SecondContract::Compiler::Message.new
  end

  describe "#new" do
    it "takes no parameters and returns a Message object" do
      @compiler.should be_an_instance_of SecondContract::Compiler::Message
    end
  end

  describe "#format" do
    it "returns strings untouched" do
      pat = @parser.parse("This is a simple string.")
      res = @compiler.format(nil, pat, {})
      res.should eq "This is a simple string."
    end
  end

  describe "#pluralize" do
    it "pluralizes simple things" do
      @compiler.pluralize("dog").should eq "dogs"
      @compiler.pluralize("fly").should eq "flies"
      @compiler.pluralize("octopus").should eq "octopi"
    end

    it "pluralizes some odd words" do
      @compiler.pluralize("moose").should eq "moose"
      @compiler.pluralize("child").should eq "children"
    end
  end

  describe "#cardinal" do
    it "returns positive numbers correctly" do
      @compiler.cardinal(1).should eq "one"
      @compiler.cardinal(13).should eq "thirteen"
      @compiler.cardinal(213).should eq "two hundred thirteen"
      @compiler.cardinal(132).should eq "one hundred thirty-two"
      @compiler.cardinal(1360).should eq "one thousand three hundred sixty"
      @compiler.cardinal(918273).should eq "nine hundred eighteen thousand two hundred seventy-three"
      @compiler.cardinal(1029384).should eq "one million twenty-nine thousand three hundred eighty-four"
    end

    it "returns negative numbers correctly" do
      @compiler.cardinal(-23).should eq ("negative " + @compiler.cardinal(23))
      @compiler.cardinal(-4468239).should eq ("negative " + @compiler.cardinal(4468239))
    end
  end

  describe "#consolidate" do
    it "returns a cardinal and proper plural" do
      @compiler.consolidate(1, "a rose").should eq "a rose"
      @compiler.consolidate(3, "a rose").should eq "three roses"
      @compiler.consolidate(12, "egg").should eq "twelve eggs"
    end

    it "respects parenthesis and brackets" do
      @compiler.consolidate(3, "a rose (red)").should eq "three roses (red)"
      @compiler.consolidate(4, "a broom [wicker]").should eq "four brooms [wicker]"
      @compiler.consolidate(3, "(rose)").should eq "(three roses)"
      @compiler.consolidate(4, "[broom]").should eq "[four brooms]"
    end
  end

  describe "#item_list" do
    it "returns a consolidated list of items" do
      @compiler.item_list([
        'a foo',
        'a bar',
        'a baz',
        'a barn',
        'a bar'
      ]).should eq "two bars, a barn, a baz, and a foo"
      @compiler.item_list([
        'an apple',
        'a pear',
        'a banana',
        'a pear'
      ]).should eq 'an apple, a banana, and two pears'
    end
  end

  describe "#format (with substitutions)" do
    it "substitutes actor appropriately" do
      msgparse = @parser.parse("<actor> <think>.")
      @compiler.format(
        "Adam", 
        msgparse, 
        { 
          actor: "Adam" 
        }
      ).should eq "You think."

      @compiler.format(
        "Bill",
        msgparse,
        {
          actor: "Adam"
        }
      ).should eq "Adam thinks."
    end

    it "substitutes direct objects appropriately" do
      msgparse = @parser.parse("<actor> <look> at <direct>.")
      @compiler.format(
        "Adam",
        msgparse, 
        { 
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ] 
        }
      ).should eq "You look at two apples, a jug of water, and a table."
      
      @compiler.format(
        "Bill",
        msgparse,
        {
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ]
        }
      ).should eq "Adam looks at two apples, a jug of water, and a table."

      @compiler.format(
        "a table",
        msgparse,
        {
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ]
        }
      ).should eq "Adam looks at two apples, a jug of water, and you."
    end
  end
end