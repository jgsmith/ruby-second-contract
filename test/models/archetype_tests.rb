require 'second-contract/parser/script'
require 'second-contract/model/archetype'

describe Archetype do
  let(:parser) { SecondContract::Parser::Script.new }

  describe "#new" do
    let(:archetype) {
      parse = parser.parse_archetype("")
      parse[:mixins] = {}
      Archetype.new(parse)
    }

    it "takes a parsed definition and returns an Archetype object" do
      expect(archetype).to be_an_instance_of Archetype
    end
  end

  describe "#set_trait and #get_trait" do
    let(:archetype) {
      archetype = Archetype.new({})
      archetype.set_trait("foo", 5)
      archetype
    }

    it "should reflect the value set" do
      expect(archetype.get_trait("foo")).to be 5
      expect(archetype.trait("foo")).to be 5
    end
  end

  describe "#calculated?" do
    let(:archetype) {
      parse = parser.parse_archetype(<<EOT)
trait:foo starts as 5
calculates trait:bar with trait:foo * 2
EOT
      parse[:mixins] = {}
      Archetype.new(parse)
    }

    it "returns true if a value is calculated as needed" do
      expect(archetype).to be_an_instance_of Archetype
      expect(archetype.errors?).to eq false
      expect(archetype.calculated?(:trait, "foo")).to eq false
      expect(archetype.calculated?(:trait, "bar")).to eq true
    end
  end

  describe "#calculate" do
    let(:quality) {
      parse = parser.parse_mixin(<<EOT)
calculates trait:boo with trait:baz + 3
EOT
      parse[:mixins] = {}
      parse[:name] = 'foo'
      Quality.new(parse)
    }
    let(:archetype) {
      parse = parser.parse_archetype(<<EOT)
trait:foo starts as 6
calculates trait:bar with trait:foo * 2
calculates trait:baz with 5
EOT
      parse[:mixins] = {
        'foo' => quality,
      }
      Archetype.new(parse)
    }

    let(:objects) {
      { this: archetype }
    }

    it "returns a calculated constant" do
      expect(archetype).to be_an_instance_of Archetype
      expect(archetype.errors?).to eq false
      expect(archetype.calculated?(:trait, "baz")).to eq true
      expect(archetype.calculate(:trait, "baz", objects)).to eq 5
      expect(archetype.trait("baz", objects)).to eq 5
      expect(archetype.trait("foo", objects)).to eq 6
      expect(archetype.trait("bar", objects)).to eq 12
      expect(archetype.trait("boo", objects)).to eq 8
    end
  end

  describe "details" do
    let(:archetype) {
      parse = parser.parse_archetype(<<'EOT')
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
      parse[:mixins] = {}
      Archetype.new(parse)
    }

    let(:data_archetype) {
      parse = parser.parse_archetype(<<'EOT')
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
      parse[:mixins] = {}
      Archetype.new(parse)
    }

    let(:child_archetype) { Archetype.new({
      archetype: archetype
    })}

    it "sets detail info" do
      expect(archetype.detail('default:name')).to eq "alien tech museum"
      expect(archetype.describe_detail(key: "floor-dust")).to eq "The dust is powdery and white, as if it drifted down from elsewhere. It is lying on the lobby floor."
      expect(archetype.describe_detail(key: "floor")).to eq "The lobby floor is smooth, though a thin layer of white dust covers it."
      expect(archetype.describe_detail).to eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling. A thin layer of white dust covers the floor."
    end

    it "inherits detail info" do
      expect(child_archetype.detail('default:name')).to eq "alien tech museum"
      expect(child_archetype.describe_detail(key: "floor-dust")).to eq "The dust is powdery and white, as if it drifted down from elsewhere. It is lying on the lobby floor."
      expect(child_archetype.describe_detail(key: "floor")).to eq "The lobby floor is smooth, though a thin layer of white dust covers it."
      expect(child_archetype.describe_detail).to eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling. A thin layer of white dust covers the floor."
    end

    it "sets detail info" do
      expect(data_archetype.detail('default:name')).to eq "alien tech museum"
      expect(data_archetype.describe_detail(times: ['day'])).to eq "The lobby of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, whirling around in circles. A thin layer of white dust covers the floor."
      expect(data_archetype.describe_detail(times: ['night'])).to eq "The loggy of the Alien Tech Museum is spacious. A model of a flying saucer hangs from the ceiling, still as can be waiting for morning. A thin layer of white dust covers the floor."
    end
  end
end