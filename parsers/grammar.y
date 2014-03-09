class Grammar

token SLASH
token LANGUAGE ADVERB VERB COMM_VERB WORD STRING NUMBER MOVEMENT_VERB
token ABOUT AND A AN ANY ALL AGAINST AT
token BEHIND BEFORE BESIDE BLOCKING
token CLOSE CONTAINING
token FRONT FROM
token GUARDING
token HOLDING HER HIS
token IN ITS
token MY
token NEAR
token OF ON OVER
token THEN TO THAT THROUGH THE THEIR
token USING UNDER
token WITH
token AND_THEN

start sentence

rule

  sentence: commands { result = { commands: val[0] } }
          | commands STRING { result = { commands: val[0], exclamation: val[1] } }
          | communication { result = { commands: [ val[0] ] } }
          | adverbs communication STRING adverbs {
            cmd = merge_commands(val[0], val[1], val[3])
            cmd[:communication] = val[2]
            result = { commands: [ cmd ] }
          }
          | adverbs communication topic {
            cmd = merge_commands(val[0], val[1], val[2])
            result = { commands: [ cmd ] }
          }

  commands: adverbs command { result = [ merge_commands(val[0], val[1]) ] }
          | commands and_then adverbs command { result = val[0] + [ merge_commands(val[2], val[3] ) ] }
  
  and_then: THEN
          | AND_THEN

  command: ttv
         | btv
         | tv
         | mv
         | verb_only

  communication: comm {
    result = merge_commands(val[0], val[1]) 
  }

  comm_verb_only: COMM_VERB adverbs {
    result = merge_commands(val[1], {
      verb: val[0]
    })
  }

  comm_language: IN LANGUAGE adverbs {
    result = merge_commands(val[2], {
      language: val[1]
    })
  }

  comm_target: indirect_noun_phrase adverbs {
    result = merge_commands(val[1], {
      target: val[0]
    })
  }

  comm: comm_verb_only
      | comm_verb_only comm_language {
        result = merge_commands(val[0], val[1])
      }
      | comm_verb_only comm_target {
        result = merge_commands(val[0], val[1])
      }
      | comm_verb_only comm_language comm_target {
        result = merge_commands(val[0], val[1], val[2])
      }
      | comm_verb_only comm_target comm_language {
        result = merge_commands(val[0], val[1], val[2])
      }
      | comm_language comm_verb_only {
        result = merge_commands(val[0], val[1])
      }
      | comm_language comm_verb_only comm_target {
        result = merge_commands(val[0], val[1], val[2])
      }
      | comm_language comm_target comm_verb_only {
        result = merge_commands(val[0], val[1], val[2])
      }
      | comm_target comm_verb_only {
        result = merge_commands(val[0], val[1])
      }
      | comm_target comm_verb_only comm_language {
        result = merge_commands(val[0], val[1], val[2])
      }
      | comm_target comm_language comm_verb_only {
        result = merge_commands(val[0], val[1], val[2])
      }

  topic: topic_intro words { 
    result = {
      topic: val[1] 
    }
  }

  topic_intro: ABOUT | THAT

  verb_only: VERB adverbs {
             result = merge_commands(val[1], {
               verb: val[0]
             })
           }
           | movement_verb_only

  movement_verb_only: MOVEMENT_VERB adverbs {
    result = merge_commands(val[1], {
      verb: val[0]
    })
  }

  mv: movement_verb_only dmp {
      result = merge_commands(val[0], val[1])
    }

  tv: verb_only dnp {
      result = merge_commands(val[0], val[1])
    }
    | dnp verb_only {
      result = merge_commands(val[0], val[1])
    }

  btv: verb_only indirect_noun_phrase dnp {
       result = merge_commands(val[0], val[1], val[2])
     }
     | tv indirect_noun_phrase {
       result = merge_commands(val[0], val[1])
     }
     | dnp indirect_noun_phrase verb_only {
       result = merge_commands(val[0], val[1], val[2])
     }
     | indirect_noun_phrase tv {
       result = merge_commands(val[0], val[1])
     }
     | movement_verb_only indirect_noun_phrase {
       result = merge_commands(val[0], val[1])
     }
     | indirect_noun_phrase movement_verb_only {
       result = merge_commands(val[0], val[1])
     }

  ttv: btv instrument_noun_phrase {
       result = merge_commands(val[0], val[1])
     }
     | instrument_noun_phrase btv {
       result = merge_commands(val[0], val[1])
     }
     | verb_only indirect_noun_phrase instrument_noun_phrase dnp {
       result = merge_commands(val[0], val[1], val[2], val[3])
     }
     | tv instrument_noun_phrase indirect_noun_phrase {
       result = merge_commands(val[0], val[1], val[2])
     }
     | dnp instrument_noun_phrase indirect_noun_phrase verb_only {
       result = merge_commands(val[0], val[1], val[2], val[3])
     }
     | indirect_noun_phrase instrument_noun_phrase tv {
       result = merge_commands(val[0], val[1], val[2])
     }

  adverbs: { result = { adverbs: [] } }
         | adverbs opt_and ADVERB { 
           result = val[0]
           result[:adverbs] << val[2] 
         }

  opt_and: { result = '' }
         | AND { result = 'and' }

  word: WORD
      #| VERB
      #| COMM_VERB
      | FRONT
      | LANGUAGE

  words: word { result = [ val[0] ] }
       | words word { result = val[0] + [ val[1] ] }

  instrument_preposition: WITH
                        | USING
                        | IN

  rel_preposition: IN | ON | AGAINST | CLOSE | CLOSE TO | UNDER | NEAR | OVER
                 | BEHIND | BEFORE | IN FRONT OF | BESIDE | CONTAINING | HOLDING
                 | WITH | GUARDING | BLOCKING

  motion_relation: IN TO | ON TO | AGAINST | CLOSE TO | UNDER | NEAR | OVER
                 | BEHIND | BEFORE | IN FRONT OF | BESIDE | AT

  indirect_preposition: FROM | TO | AT | THROUGH
                      | FROM rel_preposition
                      | TO rel_preposition

  dnp: objects adverbs {
    result = merge_commands(val[1], {
      direct: val[0]
    })
  }

  dmp: motion_relation objects adverbs {
    result = merge_commands(val[2], {
      direct: val[0].merge({
        direct_preposition: val[0]
      })
    })
  }

  indirect_noun_phrase: indirect_preposition objects adverbs {
    result = merge_commands(val[2], {
      indirect: val[1],
      indirect_preposition: val[0]
    })
  }

  instrument_noun_phrase: instrument_preposition objects adverbs {
    result = merge_commands(val[2], {
      instrument: val[1],
      instrument_preposition: val[0]
    })
  }

  noun_phrase: opt_quantifier words {
    result = {
      quantifier: val[0],
      adjectives: val[1].take(val[1].length-1),
      nominal: val[1].last
    }
  }

  objects: noun { result = [ val[0] ] }
         | objects conjunction noun { result = val[0] + [ val[2] ] }

  noun: ALL { 
        result = {
          quantifier: {
            quantity: 'all'
          }
        }
      }
      | noun_phrase
      | noun rel_preposition noun_phrase {
        result = merge_commands(val[0], {
          relation: {
            preposition: val[1],
            target: val[2]
          }
        })
      }

  conjunction: AND

  #adjectives: { result = [] }
  #          | adjectives word { result = val[0]; result << val[1] }

  article: THE | A | AN | ANY | MY | HER | HIS | ITS | THEIR

  quantifier: article {
              result = { article: val[0] }
            }
            | article NUMBER {
              result = {
                article: val[0],
                quantity: val[1]
              }
            }
            | NUMBER {
              result = {
                quantity: val[1]
              }
            }
            | ALL {
              result = {
                quantity: 'all'
              }
            }
            | fraction {
              result = {
                quantity: val[0]
              }
            }

  quantifiers: quantifier
             | quantifiers OF quantifier {
               if val[0][:quantity].is_a?(Array)
                 result = val[0]
               else
                 result = {
                   quantity: [ val[0] ]
                 }
               end
               result[:quantity] += [ val[2] ]
             }

  opt_quantifier: { result = {} }
                | quantifiers

  fraction: NUMBER SLASH NUMBER {
            result = [ val[0], val[1] ]
          }

---- inner

attr_accessor :debug

def initialize
  @special_words = %w(
    ABOUT AND A AN ANY ALL AGAINST AT
    BEHIND BEFORE BESIDE BLOCKING
    CLOSE CONTAINING
    FRONT FROM
    GUARDING
    HOLDING HER HIS
    IN ITS
    MY
    NEAR
    OF ON OVER
    THEN TO THAT THROUGH THE THEIR
    USING UNDER
    WITH
  )
  @verbs = []
  @adverbs = []
  @comm_verbs = []
  @movement_verbs = []
  @languages = []
end

def merge_commands *args
  res = {}
  args.each do |h|
    h.each do |k,v|
      case k
      when :adverbs
        if !res.include?(:adverbs)
          res[:adverbs] = []
        end
        res[:adverbs] += v
      when :direct
        if !res.include?(:direct)
          res[:direct] = []
        end
        res[:direct] += v
      else
        res[k] = v
      end
    end
  end
  res
end

def add_verb klass, v
  case klass.to_sym
  when :communication
    @comm_verbs << v
  when :movement
    @movement_verbs << v
  else
    @verbs << v
  end
end

def add_adverb av
  @adverbs << av
end

def add_language l
  @languages << l
end

def next_token
  @token = [ false, '$' ]
  @source.skip(/\s+/)
  if @queue.length > 0
    @token = @queue.shift
  elsif !@source.eos?
    pos = @source.pos
    case
    when @source.scan(/"([^"]*)"\s*/)
      @token = [ :STRING, @source[1] ]
    when @source.scan(/;\s*/)
      @token = [ :AND_THEN, ';' ]
      @verb_seen = false
    when @source.scan(/\/\s*/)
      @token = [ :SLASH, '/' ]
    when @source.scan(/(\d+)\s*/)
      @token = [ :NUMBER, @source[1].to_i ]
    when @source.scan(@verb_regex)
      if @verb_seen
        @token = [ :WORD, @source[1] ]
      else
        @token = [ :VERB, @source[1].downcase ]
        @verb_seen = true
      end
    when @source.scan(@comm_regex)
      if @verb_seen
        @token = [ :WORD, @source[1] ]
      else
        @token = [ :COMM_VERB, @source[1].downcase ]
        @verb_seen = true
      end
    when @source.scan(@movement_regex)
      if @verb_seen
        @token = [ :WORD, @source[1] ]
      else
        @token = [ :MOVEMENT_VERB, @source[1].downcase ]
        @verb_seen = true
      end
    when @source.scan(@adverb_regex)
      @token = [ :ADVERB, @source[1].downcase ]
    when @source.scan(@language_regex)
      @token = [ :LANGUAGE, @source[1].downcase ]
    when @source.scan(/(and\s+then)\s+/)
      @token = [ :AND_THEN, @source[1] ]
      @verb_seen = false
    when @source.scan(@special_regex)
      @token = [ @source[1].upcase.to_sym, @source[1].downcase ]
      if @token[0] == :THEN
        @verb_seen = false
      end
    when @source.scan(/(\S+)\s+/)
      @token = [ :WORD, @source[1] ]
    else
      @source.skip(/\S+\s*/)
    end
    if pos == @source.pos
      # nothing matched
      @token = [ false, '$' ]
    end
    if @token.first == :WORD && @token.last =~ /\s/
      words = @token.last.split(/\s+/)
      @token[1] = words.shift
      @queue.concat words.map { |w| [ :WORD, w ] }
    end
  end
  puts @token.join(" => ") + " : [#{@source.rest}]" if @debug && !@token.nil?
  @token
end

def on_error(*args)
  #puts "Error around '" + (args[2].select{ |v| v.is_a?(String) }.join(" ")) + " " + args[1] + "'"
  @failed = true
end

def failed?
  @failed
end

def make_regex list
  Regexp.new("(" + list.sort{ |a,b| b.length - a.length }.map{|v| v.gsub(/\s+/, "\\s+")}.join("|") + ")\\s+")
end

def parse(text)
  @failed = false
  bits = text.split(/"/)
  if text.start_with?('"')
    bits.unshift ""
  end
  if text.end_with?('"')
    bits.push ""
  end
  i = 0
  while i < bits.length
    bits[i].gsub!(/,/,' ')
    i += 2
  end
  text = bits.join('"')
  text.gsub!(/\s*;\s*/, ' ; ')

  @source = StringScanner.new(text.strip.sub(/\s+/, " ")+" ")
  @verb_regex = make_regex(@verbs)
  @comm_regex = make_regex(@comm_verbs)
  @movement_regex = make_regex(@movement_verbs)
  @language_regex = make_regex(@languages)
  @adverb_regex = make_regex(@adverbs)
  @special_regex = make_regex(@special_words.map{ |w| w.downcase })
  @verb_seen = false
  @queue = []

  do_parse
end