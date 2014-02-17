require 'second-contract/parser/grammar'

describe Grammar do
  let(:parser) { Grammar.new }

  describe "#new" do
    it "takes no parameters and returns a Grammar parsing object" do
      expect(parser).to be_an_instance_of Grammar
    end
  end

  describe "parsing simple verbs" do
    let(:look_parser) {
      p = Grammar.new
      p.add_verb("look")
      p.add_verb("look at")
      p.add_verb("run")
      p.add_verb("run away")
      p
    }

    let(:look_res) { 
      ['look', 'look at'].inject({}) { |h,v|
        h[v] = look_parser.parse(v)
        h
      }
    }
    ['look', 'look at'].each do |verb|
      it "parses #{verb} without any additional arguments, adverbs, etc." do
        expect(look_res[verb]).to be_an_instance_of Hash
        expect(look_res[verb][:commands]).to be_an_instance_of Array
        expect(look_res[verb][:commands].length).to eq 1
        expect(look_res[verb][:commands][0]).to be_an_instance_of Hash
        expect(look_res[verb][:commands][0][:verb]).to eq verb
      end
    end

    [
      {
        :sentence => 'look and then run away',
        :verbs => ['look', 'run away']
      },
      {
        :sentence => 'look, then run away',
        :verbs => ['look', 'run away']
      }
    ].each do |info|
      describe "strung together (#{info[:sentence]})" do
        let(:res) { look_parser.parse(info[:sentence]) }
        it {
          expect(res).to be_an_instance_of Hash
          expect(res[:commands].length).to eq 2
          expect(res[:commands][0]).to be_an_instance_of Hash
          expect(res[:commands].map{|h| h[:verb]}).to eq info[:verbs]
        }
      end
    end
  end

  describe "parsing verbs and adverbs together" do
    let(:adverb_parser) {
      p = Grammar.new
      p.add_verb("run")
      p.add_verb("run away")
      p.add_adverb("quickly")
      p.add_adverb("softly")
      p.add_adverb("loudly")
      p.add_adverb("carefully")
      p
    }

    ['run', 'run away'].each do |verb|
      [
        {
          :sentence => "#{verb} quickly",
          :adverbs => ['quickly']
        },
        {
          :sentence => "softly #{verb} quickly",
          :adverbs => ['quickly', 'softly']
        },
        {
          :sentence => "softly #{verb} quickly and carefully",
          :adverbs => ['carefully', 'quickly', 'softly']
        }
      ].each do |info|
        describe "allows the verb #{verb} to be parsed in '#{info[:sentence]}'" do
          let(:parse) { adverb_parser.parse(info[:sentence]) }
          it {
            expect(parse).to be_an_instance_of Hash
            expect(parse[:commands]).to be_an_instance_of Array
            expect(parse[:commands].length).to eq 1
            expect(parse[:commands][0]).to be_an_instance_of Hash
            expect(parse[:commands][0][:verb]).to eq verb
            expect(parse[:commands][0][:adverbs].sort).to eq info[:adverbs].sort
          }
        end
      end
    end

    ['run', 'run away'].each do |verb|
      [
        {
          :sentence => "#{verb}, quickly",
          :adverbs => ['quickly']
        },
        {
          :sentence => "softly, #{verb}, quickly",
          :adverbs => ['quickly', 'softly']
        },
        {
          :sentence => "softly, #{verb}, quickly, and carefully",
          :adverbs => ['carefully', 'quickly', 'softly']
        }
      ].each do |info|
        describe "allows the verb #{verb} to be parsed in '#{info[:sentence]}' ignoring commas not in quoted strings" do
          let(:parse) { adverb_parser.parse(info[:sentence]) }
          it {
            expect(parse).to be_an_instance_of Hash
            expect(parse[:commands]).to be_an_instance_of Array
            expect(parse[:commands].length).to eq 1
            expect(parse[:commands][0]).to be_an_instance_of Hash
            expect(parse[:commands][0][:verb]).to eq verb
            expect(parse[:commands][0][:adverbs].sort).to eq info[:adverbs].sort
          }
        end
      end
    end
  end

  describe "parsing verbs with direct objects" do
    let(:grab_parser) {
      p = Grammar.new
      p.add_verb("grab")
      p.add_movement_verb("run")
      p.add_adverb("quickly")
      p
    }

    subject(:res1) { grab_parser.parse("grab the china") }
    subject(:res2) { grab_parser.parse("grab the china and then quickly run through the door, \"Ahhhhhh!\"") }
    subject(:res3) { grab_parser.parse("grab the china; quickly run through the door, \"Ahhhhhh!\"") }

    it "works with a simple direct object" do
      expect(res1).to be_an_instance_of Hash
      expect(res1[:commands]).to be_an_instance_of Array
      expect(res1[:commands].length).to eq 1
      expect(res1[:commands][0]).to be_an_instance_of Hash
      expect(res1[:commands][0][:verb]).to eq "grab"
    end

    it "works with a simple direct object in a complex sentence" do
      expect(res2).to be_an_instance_of Hash
      expect(res2[:commands]).to be_an_instance_of Array
      expect(res2[:commands].length).to eq 2
      expect(res2[:commands][0]).to be_an_instance_of Hash
      expect(res2[:commands][0][:verb]).to eq "grab"
      expect(res2[:commands][1][:verb]).to eq "run"
      expect(res2[:exclamation]).to eq "Ahhhhhh!"
    end

    it "works with a simple direct object in a complex sentence using a semicolon" do
      expect(res3).to be_an_instance_of Hash
      expect(res3[:commands]).to be_an_instance_of Array
      expect(res3[:commands].length).to eq 2
      expect(res3[:commands][0]).to be_an_instance_of Hash
      expect(res3[:commands][0][:verb]).to eq "grab"
      expect(res3[:commands][1][:verb]).to eq "run"
      expect(res3[:exclamation]).to eq "Ahhhhhh!"
    end
  end
end