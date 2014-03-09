#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.11
# from Racc grammer file "".
#

require 'racc/parser.rb'
class Grammar < Racc::Parser

module_eval(<<'...end grammar.y/module_eval...', 'grammar.y', 314)

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
...end grammar.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
   -44,    89,     6,   144,    92,     7,    18,   138,   -44,     6,
   138,   136,   138,  -125,   136,    31,   136,  -125,     7,    56,
    33,    61,   -53,    47,    48,    49,    44,     7,   134,   137,
    37,   -44,   137,    93,   137,  -125,    20,   143,   -44,    51,
    52,    95,    53,    50,   -44,    21,   -44,   -44,   142,   176,
   164,   138,    46,    54,    39,   136,    38,   -53,    31,     6,
  -121,    95,    56,    33,   163,    37,    47,    48,    49,    44,
    14,    14,   -53,   137,    39,   166,    38,   178,    12,    12,
    37,    14,    51,    52,    29,    53,    50,   165,    17,    12,
   -53,    13,    13,    15,    15,    46,    54,    39,    37,    38,
   -53,    31,    13,     6,    15,    56,    33,   -53,    37,    47,
    48,    49,    44,   -53,    14,    37,   -53,   134,    31,   131,
   180,    37,    12,    33,    37,    51,    52,    95,    53,    50,
   134,    31,   152,     6,    87,    13,    33,    15,    46,    54,
    39,    14,    38,   -53,    14,    14,    61,   153,    14,    12,
    31,    37,    12,    12,    56,    33,    12,    95,    47,    48,
    49,    44,    13,   134,    15,    13,    13,    15,    15,    13,
    39,    15,    38,   -53,    51,    52,    95,    53,    50,    31,
   nil,    37,   nil,   nil,    33,   -53,  -125,    46,    54,    39,
  -125,    38,    56,    37,   -53,    31,    47,    48,    49,    44,
    33,    14,    37,   nil,   nil,   nil,   nil,   nil,  -125,    12,
   nil,   nil,    51,    52,   nil,    53,    50,   nil,   nil,   nil,
   nil,   nil,    13,    31,    15,    46,    54,    56,    33,   nil,
   nil,    47,    48,    49,    44,   nil,    14,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,    12,   nil,   nil,    51,    52,   nil,
    53,    50,   nil,   nil,   nil,   nil,    14,    13,    31,    15,
    46,    54,    56,    33,    12,   nil,    47,    48,    49,    44,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    13,   nil,    15,
   nil,   nil,    51,    52,   nil,    53,    50,   nil,   nil,    31,
   nil,   nil,   nil,    56,    33,    46,    54,    47,    48,    49,
    44,    56,   nil,   nil,   nil,    47,    48,    49,    44,   nil,
   nil,   nil,   nil,    51,    52,   nil,    53,    50,   nil,     6,
   nil,    51,    52,    95,    53,    50,    46,    54,    31,   nil,
   nil,    14,   nil,    33,    46,    54,    39,   nil,    38,    12,
    14,    14,   nil,   nil,     7,   nil,   nil,   nil,    12,    12,
   nil,    56,    13,    95,    15,    47,    48,    49,    44,   nil,
   nil,    13,    13,    15,    15,   nil,    39,   nil,    38,   nil,
   nil,    51,    52,    56,    53,    50,   nil,    47,    48,    49,
    44,   nil,    14,   nil,    46,    54,   nil,   nil,   nil,   nil,
    12,   nil,   nil,    51,    52,    56,    53,    50,   nil,    47,
    48,    49,    44,    13,   nil,    15,    46,    54,   nil,   nil,
   nil,   nil,    14,   nil,   nil,    51,    52,    56,    53,    50,
    12,    47,    48,    49,    44,     7,    14,   nil,    46,    54,
   nil,   nil,   nil,    13,    12,    15,   nil,    51,    52,    56,
    53,    50,   nil,    47,    48,    49,    44,    13,   nil,    15,
    46,    54,   nil,   nil,   nil,   nil,   nil,   nil,   nil,    51,
    52,    56,    53,    50,   nil,    47,    48,    49,    44,   nil,
   nil,   nil,    46,    54,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,    51,    52,    56,    53,    50,   nil,    47,    48,    49,
    44,   nil,   nil,   nil,    46,    54,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,    51,    52,    56,    53,    50,   nil,    47,
    48,    49,   175,   nil,   nil,   nil,    46,    54,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,    51,    52,    56,    53,    50,
   nil,    47,    48,    49,    44,   nil,   nil,   nil,    46,    54,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    51,    52,    56,
    53,    50,   nil,    47,    48,    49,   175,   nil,   nil,   nil,
    46,    54,   nil,   nil,   nil,   nil,   nil,   nil,   nil,    51,
    52,   nil,    53,    50,    71,   nil,    76,    77,    78,    83,
    72,    79,    46,    54,    82,    80,   nil,   nil,    69,   nil,
   nil,    74,   nil,    70,    75,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    73,    81,    71,   nil,    76,    77,    78,    83,
    72,    79,   nil,   nil,    82,    80,   nil,   nil,    69,   nil,
   nil,    74,   nil,    70,    75,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    73,    81,    71,   nil,    76,    77,    78,    83,
    72,    79,   nil,   nil,    82,    80,   nil,   nil,    69,   nil,
   nil,    74,   nil,    70,    75,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    73,    81,    71,   nil,    76,    77,    78,    83,
    72,    79,   nil,   nil,    82,    80,   nil,   nil,    69,   nil,
   nil,    74,   nil,    70,    75,   110,   118,   115,   116,   117,
   nil,   111,    73,    81,    12,   nil,   nil,   nil,   nil,   108,
   nil,   nil,   113,   nil,   109,   114,   nil,    13,   nil,    15,
   nil,   nil,   nil,   112 ]

racc_action_check = [
   100,    22,    11,    59,    22,    64,     2,    42,   100,    66,
   158,    42,    91,    30,   158,    30,    91,    30,    67,    30,
    30,     7,   105,    30,    30,    30,    30,    11,   135,    42,
   105,   100,   158,    22,    91,    30,     2,    56,   100,    30,
    30,    30,    30,    30,   100,     2,   100,   100,    55,   143,
   108,   140,    30,    30,    30,   140,    30,     4,     4,     4,
    44,    25,     4,     4,   108,     4,     4,     4,     4,     4,
   124,     4,    60,   140,    25,   111,    25,   152,   124,     4,
    60,    65,     4,     4,     4,     4,     4,   109,     1,    65,
   157,   124,     4,   124,     4,     4,     4,     4,   157,     4,
    88,    88,    65,    68,    65,    88,    88,    62,    88,    88,
    88,    88,    88,   181,    88,    62,   172,    40,   123,    36,
   164,   181,    88,   123,   172,    88,    88,    88,    88,    88,
   167,    34,    69,    10,    17,    88,    34,    88,    88,    88,
    88,   125,    88,   145,    34,    10,    29,    72,   128,   125,
   156,   145,    34,    10,   156,   156,   128,    34,   156,   156,
   156,   156,   125,    86,   125,    34,    10,    34,    10,   128,
    34,   128,    34,   132,   156,   156,   156,   156,   156,   102,
   nil,   132,   nil,   nil,   102,   120,    28,   156,   156,   156,
    28,   156,    28,   120,   154,   169,    28,    28,    28,    28,
   169,    28,   154,   nil,   nil,   nil,   nil,   nil,    28,    28,
   nil,   nil,    28,    28,   nil,    28,    28,   nil,   nil,   nil,
   nil,   nil,    28,    35,    28,    28,    28,    35,    35,   nil,
   nil,    35,    35,    35,    35,   nil,    35,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,    35,   nil,   nil,    35,    35,   nil,
    35,    35,   nil,   nil,   nil,   nil,    63,    35,   104,    35,
    35,    35,   104,   104,    63,   nil,   104,   104,   104,   104,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    63,   nil,    63,
   nil,   nil,   104,   104,   nil,   104,   104,   nil,   nil,   129,
   nil,   nil,   nil,   129,   129,   104,   104,   129,   129,   129,
   129,    99,   nil,   nil,   nil,    99,    99,    99,    99,   nil,
   nil,   nil,   nil,   129,   129,   nil,   129,   129,   nil,     0,
   nil,    99,    99,    99,    99,    99,   129,   129,   127,   nil,
   nil,     0,   nil,   127,    99,    99,    99,   nil,    99,     0,
    26,   127,   nil,   nil,     0,   nil,   nil,   nil,    26,   127,
   nil,    16,     0,    26,     0,    16,    16,    16,    16,   nil,
   nil,    26,   127,    26,   127,   nil,    26,   nil,    26,   nil,
   nil,    16,    16,   126,    16,    16,   nil,   126,   126,   126,
   126,   nil,   126,   nil,    16,    16,   nil,   nil,   nil,   nil,
   126,   nil,   nil,   126,   126,   170,   126,   126,   nil,   170,
   170,   170,   170,   126,   nil,   126,   126,   126,   nil,   nil,
   nil,   nil,     9,   nil,   nil,   170,   170,   133,   170,   170,
     9,   133,   133,   133,   133,     9,    97,   nil,   170,   170,
   nil,   nil,   nil,     9,    97,     9,   nil,   133,   133,   119,
   133,   133,   nil,   119,   119,   119,   119,    97,   nil,    97,
   133,   133,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   119,
   119,   101,   119,   119,   nil,   101,   101,   101,   101,   nil,
   nil,   nil,   119,   119,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   101,   101,   161,   101,   101,   nil,   161,   161,   161,
   161,   nil,   nil,   nil,   101,   101,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   161,   161,   141,   161,   161,   nil,   141,
   141,   141,   141,   nil,   nil,   nil,   161,   161,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   141,   141,    41,   141,   141,
   nil,    41,    41,    41,    41,   nil,   nil,   nil,   141,   141,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,    41,    41,   144,
    41,    41,   nil,   144,   144,   144,   144,   nil,   nil,   nil,
    41,    41,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   144,
   144,   nil,   144,   144,    13,   nil,    13,    13,    13,    13,
    13,    13,   144,   144,    13,    13,   nil,   nil,    13,   nil,
   nil,    13,   nil,    13,    13,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    13,    13,    12,   nil,    12,    12,    12,    12,
    12,    12,   nil,   nil,    12,    12,   nil,   nil,    12,   nil,
   nil,    12,   nil,    12,    12,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    12,    12,    43,   nil,    43,    43,    43,    43,
    43,    43,   nil,   nil,    43,    43,   nil,   nil,    43,   nil,
   nil,    43,   nil,    43,    43,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    43,    43,   171,   nil,   171,   171,   171,   171,
   171,   171,   nil,   nil,   171,   171,   nil,   nil,   171,   nil,
   nil,   171,   nil,   171,   171,    32,    32,    32,    32,    32,
   nil,    32,   171,   171,    32,   nil,   nil,   nil,   nil,    32,
   nil,   nil,    32,   nil,    32,    32,   nil,    32,   nil,    32,
   nil,   nil,   nil,    32 ]

racc_action_pointer = [
   313,    88,    -2,   nil,    53,   nil,   nil,    18,   nil,   394,
   127,    -4,   587,   557,   nil,   nil,   342,   134,   nil,   nil,
   nil,   nil,    -7,   nil,   nil,    30,   322,   nil,   183,   143,
    10,   nil,   668,   nil,   126,   218,   115,   nil,   nil,   nil,
   105,   518,     4,   617,    25,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,    39,    35,   nil,   nil,   -32,
    68,   nil,   103,   238,   -26,    63,     3,   -13,    97,   107,
   nil,   nil,   108,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   151,   nil,    96,   nil,
   nil,     9,   nil,   nil,   nil,   nil,   nil,   408,   nil,   292,
     0,   452,   174,   nil,   253,    18,   nil,   nil,    25,    48,
   nil,    36,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   430,
   181,   nil,   nil,   113,    52,   123,   364,   323,   130,   284,
   nil,   nil,   169,   408,   nil,    16,   nil,   nil,   nil,   nil,
    48,   496,   nil,    40,   540,   139,   nil,   nil,   nil,   nil,
   nil,   nil,    42,   nil,   190,   nil,   145,    86,     7,   nil,
   nil,   474,   nil,   nil,    85,   nil,   nil,   118,   nil,   190,
   386,   647,   112,   nil,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,   109,   nil ]

racc_action_default = [
   -51,  -128,    -1,    -3,  -125,   -15,   -51,  -128,   -51,   -19,
  -128,  -128,   -92,   -93,   -94,   -95,  -125,  -128,    -2,   -51,
    -8,    -9,  -128,    -6,   -10,   -11,   -12,   -13,   -14,   -62,
   -51,   -51,   -34,   -51,  -128,  -125,  -128,   -54,   -60,   -61,
   -51,  -125,  -128,  -103,  -105,  -106,  -109,  -110,  -111,  -112,
  -113,  -114,  -115,  -116,  -117,  -118,  -120,  -122,  -123,  -126,
   -16,   -51,   -18,   -20,   -21,   -24,  -128,   -27,  -128,   -63,
   -64,   -65,   -66,   -68,   -69,   -70,   -71,   -72,   -74,   -75,
   -76,   -77,   -78,   -79,   -96,   -97,   -51,   183,  -125,   -51,
    -5,  -128,   -31,   -32,   -45,   -62,   -40,  -128,   -37,  -125,
   -34,  -125,  -128,   -42,  -125,   -33,   -36,   -43,  -128,  -128,
   -82,  -128,   -84,   -85,   -86,   -87,   -88,   -90,   -91,  -125,
   -35,   -34,   -38,  -128,  -128,   -34,  -125,  -128,  -128,  -125,
   -46,   -52,   -98,  -125,  -108,   -51,   -55,   -56,   -57,   -58,
  -102,  -125,  -119,  -128,  -128,   -17,   -22,   -23,   -25,   -26,
   -28,   -29,  -128,   -67,  -100,    -7,  -125,    -4,   -30,   -48,
   -39,  -125,   -50,   -80,  -128,   -81,   -83,   -51,   -41,  -128,
  -125,  -104,  -101,   -59,  -107,  -121,  -127,  -124,   -73,   -47,
   -89,   -99,   -49 ]

racc_goto_table = [
     4,    26,     1,    34,    32,   140,    60,    28,    94,    97,
    23,    86,    63,   104,    68,    65,    67,   124,   106,    88,
    30,    64,    66,   173,     3,    84,    85,    98,    22,    91,
   100,   105,   128,   120,   127,   125,   135,   122,   126,   130,
   132,   173,    96,    19,    99,    90,   119,     2,   107,   174,
   123,   129,   171,   177,   158,   nil,   nil,   nil,   nil,   nil,
   nil,   145,   nil,   nil,   nil,   nil,   nil,   147,   nil,   nil,
   150,   149,   nil,   151,   nil,   146,   nil,   148,   nil,   nil,
   nil,   nil,   161,   nil,   nil,    26,   154,    34,    32,   157,
   nil,    28,   nil,   nil,   155,   nil,   nil,   nil,   160,   nil,
    98,   162,   nil,   nil,   156,   122,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   159,   167,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,    98,   168,   nil,   nil,   100,
   122,   nil,   nil,   nil,   nil,   172,   nil,   nil,   nil,   104,
   169,   107,   170,   123,    96,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   100,   nil,   nil,   nil,
   179,   nil,   nil,   nil,   nil,   nil,   nil,   181,   nil,   160,
   nil,   nil,   182 ]

racc_goto_check = [
     4,    10,     1,    22,    20,    19,     4,    12,    23,    23,
     6,    30,    15,    23,    15,    14,    14,    23,    21,     4,
    17,    16,    16,    25,     3,    27,    27,    22,     3,    18,
    20,     4,    10,     4,    22,    20,    30,    12,    12,     9,
     4,    25,    17,     7,    17,     5,    28,     2,    17,    31,
    17,    17,    33,    36,    19,   nil,   nil,   nil,   nil,   nil,
   nil,     4,   nil,   nil,   nil,   nil,   nil,    15,   nil,   nil,
    15,    14,   nil,    14,   nil,    16,   nil,    16,   nil,   nil,
   nil,   nil,    23,   nil,   nil,    10,     4,    22,    20,     4,
   nil,    12,   nil,   nil,     6,   nil,   nil,   nil,    22,   nil,
    22,    10,   nil,   nil,    17,    12,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,    17,    30,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,    22,    12,   nil,   nil,    20,
    12,   nil,   nil,   nil,   nil,     4,   nil,   nil,   nil,    23,
    17,    17,    17,    17,    17,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,    20,   nil,   nil,   nil,
    22,   nil,   nil,   nil,   nil,   nil,   nil,     4,   nil,    22,
   nil,   nil,    12 ]

racc_goto_pointer = [
   nil,     2,    47,    24,     0,    23,     6,    41,   nil,     4,
    -3,   nil,     3,   nil,     5,     3,    12,    16,     7,   -37,
     0,   -14,    -1,   -17,   nil,  -117,   nil,    13,    14,   nil,
    -5,   -92,   nil,   -81,   nil,   nil,   -91,   nil,   nil ]

racc_goto_default = [
   nil,   nil,   nil,   nil,    62,   nil,   nil,   nil,    24,    25,
   103,    27,   101,     5,     9,    10,    11,     8,   nil,   nil,
   121,   nil,   102,    35,    36,   139,    41,   141,   nil,    16,
    40,    45,    42,    43,   133,    55,    58,    57,    59 ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 49, :_reduce_1,
  2, 49, :_reduce_2,
  1, 49, :_reduce_3,
  4, 49, :_reduce_4,
  3, 49, :_reduce_5,
  2, 50, :_reduce_6,
  4, 50, :_reduce_7,
  1, 55, :_reduce_none,
  1, 55, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 54, :_reduce_none,
  1, 51, :_reduce_15,
  2, 62, :_reduce_16,
  3, 63, :_reduce_17,
  2, 64, :_reduce_18,
  1, 61, :_reduce_none,
  2, 61, :_reduce_20,
  2, 61, :_reduce_21,
  3, 61, :_reduce_22,
  3, 61, :_reduce_23,
  2, 61, :_reduce_24,
  3, 61, :_reduce_25,
  3, 61, :_reduce_26,
  2, 61, :_reduce_27,
  3, 61, :_reduce_28,
  3, 61, :_reduce_29,
  2, 53, :_reduce_30,
  1, 66, :_reduce_none,
  1, 66, :_reduce_none,
  2, 60, :_reduce_33,
  1, 60, :_reduce_none,
  2, 68, :_reduce_35,
  2, 59, :_reduce_36,
  2, 58, :_reduce_37,
  2, 58, :_reduce_38,
  3, 57, :_reduce_39,
  2, 57, :_reduce_40,
  3, 57, :_reduce_41,
  2, 57, :_reduce_42,
  2, 57, :_reduce_43,
  2, 57, :_reduce_44,
  2, 56, :_reduce_45,
  2, 56, :_reduce_46,
  4, 56, :_reduce_47,
  3, 56, :_reduce_48,
  4, 56, :_reduce_49,
  3, 56, :_reduce_50,
  0, 52, :_reduce_51,
  3, 52, :_reduce_52,
  0, 72, :_reduce_53,
  1, 72, :_reduce_54,
  1, 73, :_reduce_none,
  1, 73, :_reduce_none,
  1, 73, :_reduce_none,
  1, 67, :_reduce_58,
  2, 67, :_reduce_59,
  1, 74, :_reduce_none,
  1, 74, :_reduce_none,
  1, 74, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  2, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  3, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  1, 75, :_reduce_none,
  2, 76, :_reduce_none,
  2, 76, :_reduce_none,
  1, 76, :_reduce_none,
  2, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 76, :_reduce_none,
  3, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 76, :_reduce_none,
  1, 77, :_reduce_none,
  1, 77, :_reduce_none,
  1, 77, :_reduce_none,
  1, 77, :_reduce_none,
  2, 77, :_reduce_none,
  2, 77, :_reduce_none,
  2, 70, :_reduce_98,
  3, 69, :_reduce_99,
  3, 65, :_reduce_100,
  3, 71, :_reduce_101,
  2, 79, :_reduce_102,
  1, 78, :_reduce_103,
  3, 78, :_reduce_104,
  1, 81, :_reduce_105,
  1, 81, :_reduce_none,
  3, 81, :_reduce_107,
  1, 82, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 83, :_reduce_none,
  1, 84, :_reduce_118,
  2, 84, :_reduce_119,
  1, 84, :_reduce_120,
  1, 84, :_reduce_121,
  1, 84, :_reduce_122,
  1, 86, :_reduce_none,
  3, 86, :_reduce_124,
  0, 80, :_reduce_125,
  1, 80, :_reduce_none,
  3, 85, :_reduce_127 ]

racc_reduce_n = 128

racc_shift_n = 183

racc_token_table = {
  false => 0,
  :error => 1,
  :SLASH => 2,
  :LANGUAGE => 3,
  :ADVERB => 4,
  :VERB => 5,
  :COMM_VERB => 6,
  :WORD => 7,
  :STRING => 8,
  :NUMBER => 9,
  :MOVEMENT_VERB => 10,
  :ABOUT => 11,
  :AND => 12,
  :A => 13,
  :AN => 14,
  :ANY => 15,
  :ALL => 16,
  :AGAINST => 17,
  :AT => 18,
  :BEHIND => 19,
  :BEFORE => 20,
  :BESIDE => 21,
  :BLOCKING => 22,
  :CLOSE => 23,
  :CONTAINING => 24,
  :FRONT => 25,
  :FROM => 26,
  :GUARDING => 27,
  :HOLDING => 28,
  :HER => 29,
  :HIS => 30,
  :IN => 31,
  :ITS => 32,
  :MY => 33,
  :NEAR => 34,
  :OF => 35,
  :ON => 36,
  :OVER => 37,
  :THEN => 38,
  :TO => 39,
  :THAT => 40,
  :THROUGH => 41,
  :THE => 42,
  :THEIR => 43,
  :USING => 44,
  :UNDER => 45,
  :WITH => 46,
  :AND_THEN => 47 }

racc_nt_base = 48

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "SLASH",
  "LANGUAGE",
  "ADVERB",
  "VERB",
  "COMM_VERB",
  "WORD",
  "STRING",
  "NUMBER",
  "MOVEMENT_VERB",
  "ABOUT",
  "AND",
  "A",
  "AN",
  "ANY",
  "ALL",
  "AGAINST",
  "AT",
  "BEHIND",
  "BEFORE",
  "BESIDE",
  "BLOCKING",
  "CLOSE",
  "CONTAINING",
  "FRONT",
  "FROM",
  "GUARDING",
  "HOLDING",
  "HER",
  "HIS",
  "IN",
  "ITS",
  "MY",
  "NEAR",
  "OF",
  "ON",
  "OVER",
  "THEN",
  "TO",
  "THAT",
  "THROUGH",
  "THE",
  "THEIR",
  "USING",
  "UNDER",
  "WITH",
  "AND_THEN",
  "$start",
  "sentence",
  "commands",
  "communication",
  "adverbs",
  "topic",
  "command",
  "and_then",
  "ttv",
  "btv",
  "tv",
  "mv",
  "verb_only",
  "comm",
  "comm_verb_only",
  "comm_language",
  "comm_target",
  "indirect_noun_phrase",
  "topic_intro",
  "words",
  "movement_verb_only",
  "dmp",
  "dnp",
  "instrument_noun_phrase",
  "opt_and",
  "word",
  "instrument_preposition",
  "rel_preposition",
  "motion_relation",
  "indirect_preposition",
  "objects",
  "noun_phrase",
  "opt_quantifier",
  "noun",
  "conjunction",
  "article",
  "quantifier",
  "fraction",
  "quantifiers" ]

Racc_debug_parser = true

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'grammar.y', 23)
  def _reduce_1(val, _values, result)
     result = { commands: val[0] } 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 24)
  def _reduce_2(val, _values, result)
     result = { commands: val[0], exclamation: val[1] } 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 25)
  def _reduce_3(val, _values, result)
     result = { commands: [ val[0] ] } 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 27)
  def _reduce_4(val, _values, result)
                cmd = merge_commands(val[0], val[1], val[3])
            cmd[:communication] = val[2]
            result = { commands: [ cmd ] }
          
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 32)
  def _reduce_5(val, _values, result)
                cmd = merge_commands(val[0], val[1], val[2])
            result = { commands: [ cmd ] }
          
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 36)
  def _reduce_6(val, _values, result)
     result = [ merge_commands(val[0], val[1]) ] 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 37)
  def _reduce_7(val, _values, result)
     result = val[0] + [ merge_commands(val[2], val[3] ) ] 
    result
  end
.,.,

# reduce 8 omitted

# reduce 9 omitted

# reduce 10 omitted

# reduce 11 omitted

# reduce 12 omitted

# reduce 13 omitted

# reduce 14 omitted

module_eval(<<'.,.,', 'grammar.y', 49)
  def _reduce_15(val, _values, result)
        result = merge_commands(val[0], val[1]) 
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 53)
  def _reduce_16(val, _values, result)
        result = merge_commands(val[1], {
      verb: val[0]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 59)
  def _reduce_17(val, _values, result)
        result = merge_commands(val[2], {
      language: val[1]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 65)
  def _reduce_18(val, _values, result)
        result = merge_commands(val[1], {
      target: val[0]
    })
  
    result
  end
.,.,

# reduce 19 omitted

module_eval(<<'.,.,', 'grammar.y', 72)
  def _reduce_20(val, _values, result)
            result = merge_commands(val[0], val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 75)
  def _reduce_21(val, _values, result)
            result = merge_commands(val[0], val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 78)
  def _reduce_22(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 81)
  def _reduce_23(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 84)
  def _reduce_24(val, _values, result)
            result = merge_commands(val[0], val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 87)
  def _reduce_25(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 90)
  def _reduce_26(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 93)
  def _reduce_27(val, _values, result)
            result = merge_commands(val[0], val[1])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 96)
  def _reduce_28(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 99)
  def _reduce_29(val, _values, result)
            result = merge_commands(val[0], val[1], val[2])
      
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 103)
  def _reduce_30(val, _values, result)
        result = {
      topic: val[1] 
    }
  
    result
  end
.,.,

# reduce 31 omitted

# reduce 32 omitted

module_eval(<<'.,.,', 'grammar.y', 111)
  def _reduce_33(val, _values, result)
                 result = merge_commands(val[1], {
               verb: val[0]
             })
           
    result
  end
.,.,

# reduce 34 omitted

module_eval(<<'.,.,', 'grammar.y', 118)
  def _reduce_35(val, _values, result)
        result = merge_commands(val[1], {
      verb: val[0]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 124)
  def _reduce_36(val, _values, result)
          result = merge_commands(val[0], val[1])
    
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 128)
  def _reduce_37(val, _values, result)
          result = merge_commands(val[0], val[1])
    
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 131)
  def _reduce_38(val, _values, result)
          result = merge_commands(val[0], val[1])
    
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 135)
  def _reduce_39(val, _values, result)
           result = merge_commands(val[0], val[1], val[2])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 138)
  def _reduce_40(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 141)
  def _reduce_41(val, _values, result)
           result = merge_commands(val[0], val[1], val[2])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 144)
  def _reduce_42(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 147)
  def _reduce_43(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 150)
  def _reduce_44(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 154)
  def _reduce_45(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 157)
  def _reduce_46(val, _values, result)
           result = merge_commands(val[0], val[1])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 160)
  def _reduce_47(val, _values, result)
           result = merge_commands(val[0], val[1], val[2], val[3])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 163)
  def _reduce_48(val, _values, result)
           result = merge_commands(val[0], val[1], val[2])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 166)
  def _reduce_49(val, _values, result)
           result = merge_commands(val[0], val[1], val[2], val[3])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 169)
  def _reduce_50(val, _values, result)
           result = merge_commands(val[0], val[1], val[2])
     
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 172)
  def _reduce_51(val, _values, result)
     result = { adverbs: [] } 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 174)
  def _reduce_52(val, _values, result)
               result = val[0]
           result[:adverbs] << val[2] 
         
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 178)
  def _reduce_53(val, _values, result)
     result = '' 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 179)
  def _reduce_54(val, _values, result)
     result = 'and' 
    result
  end
.,.,

# reduce 55 omitted

# reduce 56 omitted

# reduce 57 omitted

module_eval(<<'.,.,', 'grammar.y', 187)
  def _reduce_58(val, _values, result)
     result = [ val[0] ] 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 188)
  def _reduce_59(val, _values, result)
     result = val[0] + [ val[1] ] 
    result
  end
.,.,

# reduce 60 omitted

# reduce 61 omitted

# reduce 62 omitted

# reduce 63 omitted

# reduce 64 omitted

# reduce 65 omitted

# reduce 66 omitted

# reduce 67 omitted

# reduce 68 omitted

# reduce 69 omitted

# reduce 70 omitted

# reduce 71 omitted

# reduce 72 omitted

# reduce 73 omitted

# reduce 74 omitted

# reduce 75 omitted

# reduce 76 omitted

# reduce 77 omitted

# reduce 78 omitted

# reduce 79 omitted

# reduce 80 omitted

# reduce 81 omitted

# reduce 82 omitted

# reduce 83 omitted

# reduce 84 omitted

# reduce 85 omitted

# reduce 86 omitted

# reduce 87 omitted

# reduce 88 omitted

# reduce 89 omitted

# reduce 90 omitted

# reduce 91 omitted

# reduce 92 omitted

# reduce 93 omitted

# reduce 94 omitted

# reduce 95 omitted

# reduce 96 omitted

# reduce 97 omitted

module_eval(<<'.,.,', 'grammar.y', 206)
  def _reduce_98(val, _values, result)
        result = merge_commands(val[1], {
      direct: val[0]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 212)
  def _reduce_99(val, _values, result)
        result = merge_commands(val[2], {
      direct: val[0].merge({
        direct_preposition: val[0]
      })
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 220)
  def _reduce_100(val, _values, result)
        result = merge_commands(val[2], {
      indirect: val[1],
      indirect_preposition: val[0]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 227)
  def _reduce_101(val, _values, result)
        result = merge_commands(val[2], {
      instrument: val[1],
      instrument_preposition: val[0]
    })
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 234)
  def _reduce_102(val, _values, result)
        result = {
      quantifier: val[0],
      adjectives: val[1].take(val[1].length-1),
      nominal: val[1].last
    }
  
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 241)
  def _reduce_103(val, _values, result)
     result = [ val[0] ] 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 242)
  def _reduce_104(val, _values, result)
     result = val[0] + [ val[2] ] 
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 245)
  def _reduce_105(val, _values, result)
            result = {
          quantifier: {
            quantity: 'all'
          }
        }
      
    result
  end
.,.,

# reduce 106 omitted

module_eval(<<'.,.,', 'grammar.y', 253)
  def _reduce_107(val, _values, result)
            result = merge_commands(val[0], {
          relation: {
            preposition: val[1],
            target: val[2]
          }
        })
      
    result
  end
.,.,

# reduce 108 omitted

# reduce 109 omitted

# reduce 110 omitted

# reduce 111 omitted

# reduce 112 omitted

# reduce 113 omitted

# reduce 114 omitted

# reduce 115 omitted

# reduce 116 omitted

# reduce 117 omitted

module_eval(<<'.,.,', 'grammar.y', 269)
  def _reduce_118(val, _values, result)
                  result = { article: val[0] }
            
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 272)
  def _reduce_119(val, _values, result)
                  result = {
                article: val[0],
                quantity: val[1]
              }
            
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 278)
  def _reduce_120(val, _values, result)
                  result = {
                quantity: val[1]
              }
            
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 283)
  def _reduce_121(val, _values, result)
                  result = {
                quantity: 'all'
              }
            
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 288)
  def _reduce_122(val, _values, result)
                  result = {
                quantity: val[0]
              }
            
    result
  end
.,.,

# reduce 123 omitted

module_eval(<<'.,.,', 'grammar.y', 295)
  def _reduce_124(val, _values, result)
                   if val[0][:quantity].is_a?(Array)
                 result = val[0]
               else
                 result = {
                   quantity: [ val[0] ]
                 }
               end
               result[:quantity] += [ val[2] ]
             
    result
  end
.,.,

module_eval(<<'.,.,', 'grammar.y', 305)
  def _reduce_125(val, _values, result)
     result = {} 
    result
  end
.,.,

# reduce 126 omitted

module_eval(<<'.,.,', 'grammar.y', 309)
  def _reduce_127(val, _values, result)
                result = [ val[0], val[1] ]
          
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

end   # class Grammar
