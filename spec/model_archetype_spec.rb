$: << 'lib'

require 'rspec'
require 'yaml'
require 'active_record'

require 'second-contract/parser/script'
require 'second-contract/model/archetype'

describe Archetype do
  before :each do
    @parser = SecondContract::Parser::Script.new
  end

  describe "#new" do
    it "takes a parsed definition and returns an Archetype object" do
      parse = @parser.parse_archetype("")
      parse[:traits] = {}
      @archetype = Archetype.new(parse)
      @archetype.should be_an_instance_of Archetype
    end
  end

  describe "#set_trait and #get_trait" do
    it "should reflect the value set" do
      @archetype = Archetype.new({})
      @archetype.set_trait("foo", 5)
      @archetype.get_trait("foo").should be 5
      @archetype.trait("foo").should be 5
    end
  end

  describe "#calculated?" do
    it "returns true if a value is calculated as needed" do
      parse = @parser.parse_archetype(<<EOT)
trait:foo starts as 5
calculates trait:bar with trait:foo * 2
EOT
      parse[:traits] = {}
      @archetype = Archetype.new(parse)
      @archetype.should be_an_instance_of Archetype
      @archetype.errors?.should eq false
      @archetype.calculated?(:trait, "foo").should eq false
      @archetype.calculated?(:trait, "bar").should eq true
    end
  end

  describe "#calculate" do
    it "returns a calculated constant" do
      parse = @parser.parse_archetype(<<EOT)
trait:foo starts as 6
calculates trait:bar with trait:foo * 2
calculates trait:baz with 5
EOT
      parse[:traits] = {}
      @archetype = Archetype.new(parse)
      obs = { this: @archetype }
      @archetype.should be_an_instance_of Archetype
      @archetype.errors?.should eq false
      @archetype.calculated?(:trait, "baz").should eq true
      @archetype.calculate(:trait, "baz", obs).should eq 5
      @archetype.trait("baz", obs).should eq 5
      @archetype.trait("foo", obs).should eq 6
      @archetype.trait("bar", obs).should eq 12
    end
  end

  describe "details" do
    it "sets detail info" do
      parse = @parser.parse_archetype(<<'EOT')
---
details:
  default:
    name: "alien tech museum"
    article: "the"
    sight: "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling. A thin layer of white dust covers the floor."
  floor:
    name: "lobby floor"
    article: "the"
    sight: "The lobby floor is smooth, though a thin layer of white dust covers it."
    related-to:
      in: default
  floor-dust:
    name: "dust"
    sight: "The dust is powdery and white, as if it drifted down from elsewhere."
    related-to:
      "on":
        detail: floor
        position: lying
---
EOT
      parse[:traits] = {}
      @archetype = Archetype.new(parse)
      obs = { this: @archetype }
      @archetype.detail('default:name').should eq "alien tech museum"
      @archetype.describe_detail(key: "floor-dust").should eq "The dust is powdery and white, as if it drifted down from elsewhere. It is lying on the lobby floor."
      @archetype.describe_detail(key: "floor").should eq "The lobby floor is smooth, though a thin layer of white dust covers it."
      @archetype.describe_detail.should eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling. A thin layer of white dust covers the floor."

      @second_archetype = Archetype.new({
        archetype: @archetype
      })

      obs = { this: @second_archetype }

      @second_archetype.detail('default:name').should eq "alien tech museum"
      @second_archetype.describe_detail(key: "floor-dust").should eq "The dust is powdery and white, as if it drifted down from elsewhere. It is lying on the lobby floor."
      @second_archetype.describe_detail(key: "floor").should eq "The lobby floor is smooth, though a thin layer of white dust covers it."
      @second_archetype.describe_detail.should eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling. A thin layer of white dust covers the floor."

    end

    it "sets detail info" do
      parse = @parser.parse_archetype(<<'EOT')
---
details:
  default:
    name: "alien tech museum"
    article: "the"
    sight: 
      day: "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, whirling around in circles. A thin layer of white dust covers the floor."
      night: "The loggy of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, still as can be waiting for morning. A thin layer of white dust covers the floor."
---
EOT
      parse[:traits] = {}
      @archetype = Archetype.new(parse)
      obs = { this: @archetype }
      @archetype.detail('default:name').should eq "alien tech museum"
      @archetype.describe_detail(times: ['day']).should eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, whirling around in circles. A thin layer of white dust covers the floor."
      @archetype.describe_detail(times: ['night']).should eq "The loggy of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, still as can be waiting for morning. A thin layer of white dust covers the floor."
    end
  end
end