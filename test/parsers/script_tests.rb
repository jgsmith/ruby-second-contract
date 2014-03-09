require 'second-contract/parser/script'

describe SecondContract::Parser::Script do
  let!(:parser) { SecondContract::Parser::Script.new }

  describe "#new" do
    it "takes no parameters and returns a Script parsing object" do
      expect(parser).to be_an_instance_of SecondContract::Parser::Script
    end
  end

  describe "#parse_archetype" do
    let(:parse) { parser.parse_archetype(<<'EOT') }
---
traits:
  foo: 3
  bar: true
---
based on foo:bar

is apple
is pear, banana

can foo
can bar if True
can bar as actor if False
can not baz as actor
can baz unless False

calculates bar:baz with 1 + 2 * 3 + 4
calculates baz:bar with 1 * 2 + 3 * 4
calculates foo with 1 + 2
calculates bar:bq with 1 * 2 + 3 * 4 * 5 + 6
calculates eq:gt with 1 * 2 + 3 * 4 * 5 + 6 > 10
calculates eq:gt:swapped with 10 > 1 * 2 + 3 * 4 * 5 + 6
calculates inequalities with 1 < 2 and 3 > 4 or 5 <> 6
calculates traitfoo with trait:foo // 4

calculates trait:bar with 6 * 2
calculates foo:if-then-else with 
  if trait:foo then
    3
  else
    5
  end
calculates foo:if-elsif with
  if trait:foo < 3 then
    set trait:bar to 4 + 5
  elsif trait:foo < 6 then
    set trait:bar to 6 + 7
  elsif trait:foo < 10 then
    set trait:bar to 9 + 10
  else
    set trait:bar to 12 + 14 * 3
  end

calculates foo:setting with do
  set $type to 3
  unset $type
  $type - 6
end

reacts to foo with do
  :"<actor> <bounce> around."
end

reacts to bar with do
  sight:"Light glints off of falling drops of water at the other end of the corridor."
  sound:"Dripping water echoes down the corridor."@whisper+3
end

reacts to barboo with do
  Emit("test:class", "Foo" _ Describe(physical:environment) )
end

# allows a comment at the end of the file

EOT

    it "should result in a Hash" do
      expect(parse).to be_an_instance_of Hash
    end

    it "allows named archetype" do
      expect(parse[:archetype]).to eq "foo:bar"
    end

    it "allows data section at the beginning" do
      expect(parse[:data]).to be_an_instance_of Hash
      expect(parse[:data].keys.sort).to eq %w(traits:bar traits:foo)
    end

    it "allows named mixin qualities" do
      expect(parse[:mixins].sort).to eq %w(apple banana pear)
    end

    it "allows abilities" do
      expect(parse[:abilities].keys.sort).to eq %w(bar:actor bar:any baz:actor baz:any foo:any)
    end

    it "allows calculations" do
      expect(parse[:calculations].keys.sort).to eq %w(
        bar:baz 
        bar:bq 
        baz:bar 
        eq:gt 
        eq:gt:swapped 
        foo
        foo:if-elsif
        foo:if-then-else 
        foo:setting 
        inequalities
        trait:bar
        traitfoo
      ).sort
    end

    it "allows a calculation to add two things together" do
      expect(parse[:calculations]['foo'].length).to eq 3
      expect(parse[:calculations]['foo']).to eq [ 
        :PLUS, 
        [ :INT, 1 ],
        [ :INT, 2 ]
      ]
    end

    it "allows calculations to mix multiplication and addition" do
      expect(parse[:calculations]['bar:baz']).to eq [
        :PLUS,
        [ :INT, 1 ],
        [ :MPY,
          [ :INT, 2 ],
          [ :INT, 3 ]
        ],
        [ :INT, 4 ]
      ]

      expect(parse[:calculations]['baz:bar']).to eq [
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

      expect(parse[:calculations]['bar:bq']).to eq [
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
      expect(parse[:calculations]['eq:gt']).to eq [
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

      expect(parse[:calculations]['eq:gt:swapped']).to eq [
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
      expect(parse[:calculations]['inequalities']).to eq [
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
      expect(parse[:calculations]['traitfoo'].first).to eq :DEFAULT
      expect(parse[:calculations]['traitfoo'].length).to eq 3
    end

    it "allows compound expressions" do
      expect(parse[:calculations]['foo:setting'].first).to eq :COMPOUND_EXP
      expect(parse[:calculations]['foo:setting'].length).to eq 4
    end

    it "calculates with multiplication" do
      expect(parse[:calculations]['trait:bar'].first).to eq :MPY
      expect(parse[:calculations]['trait:bar'].length).to eq 3
    end

    it "allows if-then expressions" do
      expect(parse[:calculations]['foo:if-then-else'].first).to eq :WHEN
      expect(parse[:calculations]['foo:if-then-else']).to eq [
        :WHEN,
        [ [ :PROP, 'trait:foo' ],
          [ :COMPOUND_EXP,
            [ :INT, 3 ]
        ] ],
        [ :COMPOUND_EXP,
          [ :INT, 5 ]
        ]
      ]
    end

    it "allows if-then-elsif expressions" do
      expect(parse[:calculations]['foo:if-elsif'].first).to eq :WHEN
      expect(parse[:calculations]['foo:if-elsif'].length).to eq 5
    end
  end
end