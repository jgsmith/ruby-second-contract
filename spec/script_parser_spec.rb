$: << 'lib'

require 'rspec'
require 'yaml'
require 'active_record'

require 'second-contract/parser/script'

describe SecondContract::Parser::Script do
  before :each do
    @parser = SecondContract::Parser::Script.new
  end

  describe "#new" do
    it "takes no parameters and returns a Script parsing object" do
      @parser.should be_an_instance_of SecondContract::Parser::Script
    end
  end

  describe "#parse_archetype" do
    it "allows named ur-object" do
      res = @parser.parse_archetype("based on foo:bar")
      res.should be_an_instance_of Hash
      res[:archetype].should eq "foo:bar"
    end

    it "allows data section at the beginning" do
      res = @parser.parse_archetype(<<'EOT')
---
traits:
  foo: 3
  bar: true
EOT
      res[:data].should be_an_instance_of Hash
      res[:data].keys.sort.should eq %w(traits:bar traits:foo)
    end

    it "allows named traits" do
      res = @parser.parse_archetype(<<'EOT')
based on foo:bar

is apple
is pear, banana

EOT
      res.should be_an_instance_of Hash
      res[:archetype].should eq "foo:bar"
      res[:traits].sort.should eq %w(apple banana pear)
    end

    it "allows abilities" do
      res = @parser.parse_archetype(<<'EOT')
can foo
can bar if True
can bar as agent if False
can not baz as agent
can baz unless False
EOT
      res.should be_an_instance_of Hash
      res[:abilities].keys.sort.should eq %w(bar:agent bar:any baz:agent baz:any foo:any)
    end

    it "allows calculations" do
      res = @parser.parse_archetype(<<'EOT')
calculates foo with True
calculates bar:baz with False
EOT

      res.should be_an_instance_of Hash
      res[:calculations].keys.sort.should eq %w(bar:baz foo)
    end

    it "allows a calculation to add two things together" do
      res = @parser.parse_archetype("calculates foo with 1 + 2")
      res.should be_an_instance_of Hash
      res[:calculations].keys.sort.should eq %w(foo)
      res[:calculations]['foo'].length.should eq 3
      res[:calculations]['foo'].should eq [ 
        :PLUS, 
        [ :INT, 1 ],
        [ :INT, 2 ]
      ]
    end

    it "allows calculations to mix multiplication and addition" do
      res = @parser.parse_archetype("calculates foo with 1 + 2 * 3 + 4")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :PLUS,
        [ :INT, 1 ],
        [ :MPY,
          [ :INT, 2 ],
          [ :INT, 3 ]
        ],
        [ :INT, 4 ]
      ]

      res = @parser.parse_archetype("calculates foo with 1 * 2 + 3 * 4")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :PLUS,
        [ :MPY,
          [ :INT, 1 ],
          [ :INT, 2 ]
        ],
        [ :MPY,
          [ :INT, 3 ],
          [ :INT, 4 ]
        ]
      ]

      res = @parser.parse_archetype("calculates foo with 1 * 2 + 3 * 4 * 5 + 6")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :PLUS,
        [ :MPY,
          [ :INT, 1 ],
          [ :INT, 2 ]
        ],
        [ :MPY,
          [ :INT, 3 ],
          [ :INT, 4 ],
          [ :INT, 5 ]
        ],
        [ :INT, 6 ]
      ]
    end

    it "allows calculations with inequality operations" do
      res = @parser.parse_archetype("calculates foo with 1 * 2 + 3 * 4 * 5 + 6 > 10")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :GT,
        [ :PLUS,
          [ :MPY,
            [ :INT, 1 ],
            [ :INT, 2 ]
          ],
          [ :MPY,
            [ :INT, 3 ],
            [ :INT, 4 ],
            [ :INT, 5 ]
          ],
          [ :INT, 6 ]
        ],
        [ :INT, 10 ]
      ]

      res = @parser.parse_archetype("calculates foo with 10 > 1 * 2 + 3 * 4 * 5 + 6")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :GT,
        [ :INT, 10 ],
        [ :PLUS,
          [ :MPY,
            [ :INT, 1 ],
            [ :INT, 2 ]
          ],
          [ :MPY,
            [ :INT, 3 ],
            [ :INT, 4 ],
            [ :INT, 5 ]
          ],
          [ :INT, 6 ]
        ]
      ]
    end

    it "allows boolean and/or along with inequalities" do
      res = @parser.parse_archetype("calculates foo with 1 < 2 and 3 > 4 or 5 <> 6")
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].should eq [
        :OR,
        [ :AND,
          [ :LT,
            [ :INT, 1 ],
            [ :INT, 2 ]
          ],
          [ :GT,
            [ :INT, 3 ],
            [ :INT, 4 ]
          ]
        ],
        [ :NE,
          [ :INT, 5 ],
          [ :INT, 6 ]
        ]
      ]
    end

    it "allows default expressions" do
      res = @parser.parse_archetype(<<'EOT')
calculates foo with trait:foo // 3
EOT
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].first.should eq :DEFAULT
      res[:calculations]['foo'].length.should eq 3
    end

    it "allows compound expressions" do
      res = @parser.parse_archetype(<<'EOT')
calculates foo with do
  set $type to 3
  unset $type
  $type - 6
end
EOT
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].first.should eq :COMPOUND_EXP
      res[:calculations]['foo'].last.length.should eq 3
    end

    it "calculates with multiplication" do
      res = @parser.parse_archetype(<<'EOT')
calculates trait:bar with 6 * 2
EOT
      res.should be_an_instance_of Hash
      res[:calculations]['trait:bar'].first.should eq :MPY
      res[:calculations]['trait:bar'].length.should eq 3
    end

    it "allows if-then expressions" do
      res = @parser.parse_archetype(<<'EOT')
calculates foo with 
  if trait:foo then
    set trait:bar to 3
  else
    set trait:bar to 5
  end
EOT
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].first.should eq :WHEN
      res[:calculations]['foo'].should eq [
        :WHEN,
        [ [ :PROP, 'trait:foo' ],
          [ :COMPOUND_EXP, [
            [ :SET_PROP, 'trait:bar', [ :INT, 3 ] ]
          ]
        ] ],
        [ :COMPOUND_EXP, [
          [ :SET_PROP, 'trait:bar', [ :INT, 5 ] ] 
        ] ]
      ]
    end

    it "allows if-then-elsif expressions" do
      res = @parser.parse_archetype(<<'EOT')
calculates foo with
  if trait:foo < 3 then
    set trait:bar to 4 + 5
  elsif trait:foo < 6 then
    set trait:bar to 6 + 7
  elsif trait:foo < 10 then
    set trait:bar to 9 + 10
  else
    set trait:bar to 12 + 14 * 3
  end
EOT
      res.should be_an_instance_of Hash
      res[:calculations]['foo'].first.should eq :WHEN
      res[:calculations]['foo'].length.should eq 5
    end

    it "allows narration" do
      res = @parser.parse_archetype(<<'EOT')
reacts to foo with do
  :"<actor> <bounces> around."
end

reacts to bar with do
  sight:"Light glints off of falling drops of water at the other end of the corridor."
  sound:"Dripping water echoes down the corridor."@whisper+3
end
EOT
      res.should be_an_instance_of Hash
    end

    it "allows a comment at the end of a file" do
      res = @parser.parse_archetype(<<'EOT')
can foo as agent
can bar as instrument
can baz as environment

# the rest is just a comment

EOT
      res.should be_an_instance_of Hash
    end
  end
end