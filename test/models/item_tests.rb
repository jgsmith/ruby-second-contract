require 'second-contract/parser/script'
require 'second-contract/model/archetype'
require 'second-contract/model/item'
require 'second-contract/iflib/sys/binder'

describe Item do
  subject(:parser)   { SecondContract::Parser::Script.new   }

  describe "basic construction" do
    let(:parse) { 
      p = parser.parse_archetype("")
      p[:mixins] = {}
      p[:name] = 'foo'
      p
    }
    let(:archetype) { 
      a = Archetype.new(parse) 
      SecondContract::Game.instance.register_archetype('foo', a)
      a
    }
    let(:item) { 
      i = Item.create
      i.archetype = archetype
      i
    }

    it "allows setting of the archetype" do
      expect(archetype).to be_an_instance_of Archetype
      expect(item).to be_an_instance_of Item
      expect(item.archetype).to eq archetype
    end
  end

  context "the 'luggage' player object" do
    subject(:luggage) { FactoryGirl.create(:luggage_item) }
    let(:objs) { { this: luggage, actor: luggage } }

    describe "factory construction" do
      it { expect(luggage).to be_an_instance_of Item }
    end

    describe "identification" do
      it "should have a name" do
        expect(luggage.detail("default:name", objs)).to eq "luggage"
        expect(luggage.detail("default:capName", objs)).to eq "Luggage"
      end
    end

    describe "physical attributes" do
      it "should be living" do
        expect(luggage.quality("living", objs)).to eq true
        expect(luggage.physical("gender", objs)).to eq "male"
      end
    end

    describe "binding responses" do
      let(:context) { SecondContract::IFLib::Data::Context.new }
      let(:binding) { luggage.parse_match_object({adjectives: [], nominal: "human"}, luggage, context) }
      it "should get correct information for binding" do
        expect(luggage.parse_command_id_list).to eq [ 'human', 'luggage' ]
        expect(luggage.parse_command_adjective_id_list).to eq [ 'simple' ]
      end

      it "should respond to 'human'" do
        expect(luggage.is_matching_object({adjectives: [], nominal: "human"}, luggage, context)).to eq [:singular]
        expect(luggage.is_matching_object({adjectives: [], nominal: "luggage"}, luggage, context)).to eq [:singular]
        expect(luggage.is_matching_object({adjectives: ["simple"], nominal: "human"}, luggage, context)).to eq [:singular]
        expect(luggage.is_matching_object({adjectives: ["weird"], nominal: "human"}, luggage, context)).to eq []
        expect(binding.first).to include :singular
        expect(binding.last).to include luggage
      end

      it "has appropriate abilities" do
        expect(luggage.ability('move:accept:any')).to eq true
        expect(luggage.ability('scan:brief:actor')).to eq true
        expect(luggage.ability('scan:brief:direct')).to eq false
      end
    end
  end

  describe "placement in a scene" do
    subject(:luggage) { FactoryGirl.create(:luggage_item) }
    subject(:inn)     { Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first }
    subject(:placement) { place(luggage, :in, inn) }

    it "should have the inn as its environment" do
      expect(placement.source).to be luggage
      expect(placement.target).to be inn
      expect(placement.preposition).to be :in
      expect(luggage.get_environment).to eq inn
      expect(luggage.physical('environment')).to eq inn
      expect(luggage.physical('location')).to eq inn
    end
  end

  describe "reactions get run" do
    subject(:luggage) { FactoryGirl.create(:luggage_item) }
    subject(:inn)     { Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first }
    subject(:placement) { place(luggage, :behind, inn, 'bar') }
    let(:pre)  { luggage.trigger_event('pre-scan:brief-actor', {this: luggage, actor: luggage })}
    let(:post) { luggage.trigger_event('post-scan:brief-actor', {this: luggage, actor: luggage })}
    it "should have proper flags set after running pre-scan:brief as actor" do
      expect(pre).to eq true
      expect(luggage.flag('brief-scan')).to eq true
      expect(luggage.flag('scanning')).to eq true
    end
    it "should have proper flags set after running both pre- and post-scan:brief as actor" do
      expect(placement && pre && post).to eq true
      expect(luggage.flag('brief-scan')).to eq false
      expect(luggage.flag('scanning')).to eq false
    end
  end

  describe "moving from one location to another" do
    subject(:luggage) { FactoryGirl.create(:luggage_item) }
    subject(:inn)     { Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first }
    subject(:yard)    { Domain.find_by(:name => 'start').items.where(:name => 'scene:yard').first }
    subject(:placement) { place(luggage, :behind, inn, 'bar') }
    subject(:movement) { luggage.do_move("normal", :in, yard, 'default', "<actor> <leave>.", "<actor> <arrive>.")}
    let(:pre)  { luggage.trigger_event('pre-scan:brief-actor', {this: luggage, actor: luggage })}
    let(:post) { luggage.trigger_event('post-scan:brief-actor', {this: luggage, actor: luggage })}
    it "should reflect the movement of the character" do
      expect(placement && movement).to eq true
      expect(pre && post).to eq true
      expect(luggage.physical('environment')).to eq yard
    end
  end

  describe "exits from inn" do
    subject(:inn)     { Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first }
    subject(:yard)    { Domain.find_by(:name => 'start').items.where(:name => 'scene:yard').first }
    let(:exits)       { inn.detail_exits }
    it "should include 'west'" do
      expect(exits.keys).to eq ['west']
      expect(exits["west"].try(:item)).to eq yard
    end
  end

  describe "moves within a scene" do
    subject(:luggage) { FactoryGirl.create(:luggage_item) }
    subject(:inn)     { Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first }
    subject(:placement) { place(luggage, :on, inn, 'floor') }
    subject(:movement) { luggage.do_move("normal", :behind, inn, 'bar')}
    it "should reflect the movement of the character" do
      expect(placement && movement).to eq true
      expect(luggage.physical('environment')).to eq inn
      expect(luggage.physical('location').coord).to eq 'bar'
      expect(luggage.physical('location').preposition.to_s).to eq 'behind'
    end
  end
end
