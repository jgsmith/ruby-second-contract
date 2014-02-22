require 'second-contract/parser/message'
require 'second-contract/compiler/message'

describe SecondContract::Parser::Message do
  let(:compiler) { SecondContract::Compiler::Message.new }
  let(:parser)   { SecondContract::Parser::Message.new   }
  let(:english)  { SecondContract::IFLib::Sys::English.instance }

  it "is the proper class" do
    expect(compiler).to be_an_instance_of SecondContract::Compiler::Message
  end

  it "returns a string untouched" do
    expect(
      compiler.format(nil, parser.parse("This is a simple string."), {})
    ).to eq "This is a simple string."
  end

  it "pluralizes simple things" do
    expect(english.pluralize("dog")).to eq "dogs"
    expect(english.pluralize("fly")).to eq "flies"
    expect(english.pluralize("octopus")).to eq "octopi"
  end

  it "pluralizes some odd words" do
    expect(english.pluralize("moose")).to eq "moose"
    expect(english.pluralize("child")).to eq "children"
  end

  describe "#cardinal" do
    it "returns positive numbers correctly" do
      expect(english.cardinal(1)).to eq "one"
      expect(english.cardinal(13)).to eq "thirteen"
      expect(english.cardinal(213)).to eq "two hundred thirteen"
      expect(english.cardinal(132)).to eq "one hundred thirty-two"
      expect(english.cardinal(1360)).to eq "one thousand three hundred sixty"
      expect(english.cardinal(918273)).to eq "nine hundred eighteen thousand two hundred seventy-three"
      expect(english.cardinal(1029384)).to eq "one million twenty-nine thousand three hundred eighty-four"
    end

    it "returns negative numbers correctly" do
      expect(english.cardinal(-23)).to eq ("negative " + english.cardinal(23))
      expect(english.cardinal(-4468239)).to eq ("negative " + english.cardinal(4468239))
    end
  end

  describe "#consolidate" do
    it "returns a cardinal and proper plural" do
      expect(english.consolidate(1, "a rose")).to eq "a rose"
      expect(english.consolidate(3, "a rose")).to eq "three roses"
      expect(english.consolidate(12, "egg")).to eq "twelve eggs"
    end

    it "respects parenthesis and brackets" do
      expect(english.consolidate(3, "a rose (red)")).to eq "three roses (red)"
      expect(english.consolidate(4, "a broom [wicker]")).to eq "four brooms [wicker]"
      expect(english.consolidate(3, "(rose)")).to eq "(three roses)"
      expect(english.consolidate(4, "[broom]")).to eq "[four brooms]"
    end
  end

  describe "#item_list" do
    it "returns a consolidated list of items" do
      expect(english.item_list([
        'a foo',
        'a bar',
        'a baz',
        'a barn',
        'a bar'
      ])).to eq "two bars, a barn, a baz, and a foo"
      expect(english.item_list([
        'an apple',
        'a pear',
        'a banana',
        'a pear'
      ])).to eq 'an apple, a banana, and two pears'
    end
  end

  describe "#format (with substitutions)" do
    let(:actor_think) { parser.parse("<actor> <think>.") }
    let(:actor_look_at_direct) { parser.parse("<actor> <look> at <direct>.") }

    it "substitutes actor appropriately" do
      expect(compiler.format(
        "Adam", 
        actor_think, 
        { 
          actor: "Adam" 
        }
      )).to eq "You think."

      expect(compiler.format(
        "Bill",
        actor_think,
        {
          actor: "Adam"
        }
      )).to eq "Adam thinks."
    end

    it "substitutes direct objects appropriately" do
      expect(compiler.format(
        "Adam",
        actor_look_at_direct, 
        { 
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ] 
        }
      )).to eq "You look at two apples, a jug of water, and a table."
      
      expect(compiler.format(
        "Bill",
        actor_look_at_direct,
        {
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ]
        }
      )).to eq "Adam looks at two apples, a jug of water, and a table."

      expect(compiler.format(
        "a table",
        actor_look_at_direct,
        {
          actor: "Adam",
          direct: [ "a jug of water", "a table", "an apple", "an apple" ]
        }
      )).to eq "Adam looks at two apples, a jug of water, and you."
    end
  end
end