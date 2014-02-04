$: << 'lib'

require 'rspec'

require 'active_record'
require 'second-contract/parser/grammar'

describe SecondContract::Parser::Grammar do
  before :each do
    @parser = SecondContract::Parser::Grammar.new
  end

  describe "#new" do
    it "takes no parameters and returns a Grammar parsing object" do
      @parser.should be_an_instance_of SecondContract::Parser::Grammar
    end
  end

  describe "parsing simple verbs" do
    it "works without any additional arguments, adverbs, etc." do
      @parser.add_verb("look")
      @parser.add_verb("look at")

      ['look', 'look at'].each do |verb|
        res = @parser.parse(verb)
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
      end
    end

    it "works with adverbs" do
      @parser.add_verb("run")
      @parser.add_verb("run away")
      @parser.add_adverb("quickly")
      @parser.add_adverb("softly")
      @parser.add_adverb("loudly")
      @parser.add_adverb("carefully")

      ['run', 'run away'].each do |verb|
        res = @parser.parse("#{verb} quickly")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].should eq ['quickly']

        res = @parser.parse("softly #{verb} quickly")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].sort.should eq ['quickly', 'softly']

        res = @parser.parse("softly #{verb} quickly and carefully")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].sort.should eq ['carefully', 'quickly', 'softly']
      end
    end

    it "ignores commas not in quoted strings" do
      @parser.add_verb("run")
      @parser.add_verb("run away")
      @parser.add_adverb("quickly")
      @parser.add_adverb("softly")
      @parser.add_adverb("loudly")
      @parser.add_adverb("carefully")

      ['run', 'run away'].each do |verb|
        res = @parser.parse("#{verb}, quickly")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].should eq ['quickly']

        res = @parser.parse("softly, #{verb}, quickly")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].sort.should eq ['quickly', 'softly']

        res = @parser.parse("softly, #{verb}, quickly, and carefully")
        res.should be_an_instance_of Hash
        res[:commands].should be_an_instance_of Array
        res[:commands].length.should eq 1
        res[:commands][0].should be_an_instance_of Hash
        res[:commands][0][:verb].should eq verb
        res[:commands][0][:adverbs].sort.should eq ['carefully', 'quickly', 'softly']
      end
    end

    it "works with verbs strung together" do
      @parser.add_verb("look")
      @parser.add_movement_verb("run")
      @parser.add_verb("look at")
      @parser.add_verb("run away")

      # first with 'and then'
      res = @parser.parse("look and then run away")
      @parser.failed?.should eq false
      res.should be_an_instance_of Hash
      res[:commands].should be_an_instance_of Array
      res[:commands].length.should eq 2
      res[:commands][0].should be_an_instance_of Hash
      res[:commands][0][:verb].should eq 'look'
      res[:commands][1].should be_an_instance_of Hash
      res[:commands][1][:verb].should eq 'run away'

      # then with only 'then' -- the comma is ignored in the tokenization
      res = @parser.parse("look, then run away")
      @parser.failed?.should eq false
      res.should be_an_instance_of Hash
      res[:commands].should be_an_instance_of Array
      res[:commands].length.should eq 2
      res[:commands][0].should be_an_instance_of Hash
      res[:commands][0][:verb].should eq 'look'
      res[:commands][1].should be_an_instance_of Hash
      res[:commands][1][:verb].should eq 'run away'
    end
  end

  describe "parsing verbs with direct objects" do
    it "works with a simple direct object" do
      @parser.add_verb("grab")
      @parser.add_movement_verb("run")

      res = @parser.parse("grab the china")
      res.should be_an_instance_of Hash
      res[:commands].should be_an_instance_of Array
      res[:commands].length.should eq 1
      res[:commands][0].should be_an_instance_of Hash
      res[:commands][0][:verb].should eq "grab"
    end

    it "works with a simple direct object in a complex sentence" do
      @parser.add_verb("grab")
      @parser.add_adverb("quickly")
      @parser.add_movement_verb("run")

      res = @parser.parse("grab the china and then quickly run through the door, \"Ahhhhhh!\"")
      res.should be_an_instance_of Hash
      res[:commands].should be_an_instance_of Array
      res[:commands].length.should eq 2
      res[:commands][0].should be_an_instance_of Hash
      res[:commands][0][:verb].should eq "grab"
      res[:commands][1][:verb].should eq "run"
      res[:exclamation].should eq "Ahhhhhh!"
    end

    it "works with a simple direct object in a complex sentence using a semicolon" do
      @parser.add_verb("grab")
      @parser.add_adverb("quickly")
      @parser.add_movement_verb("run")

      res = @parser.parse("grab the china; quickly run through the door, \"Ahhhhhh!\"")
      res.should be_an_instance_of Hash
      res[:commands].should be_an_instance_of Array
      res[:commands].length.should eq 2
      res[:commands][0].should be_an_instance_of Hash
      res[:commands][0][:verb].should eq "grab"
      res[:commands][1][:verb].should eq "run"
      res[:exclamation].should eq "Ahhhhhh!"
    end
  end
end