class MudMode

#token CHARS
token INT
token FLOAT
token STRING
token ARRAY_SEP
token MAP_SEP
token ARRAY_START
token ARRAY_END
token MAP_START
token MAP_END
#token QUOTE

rule
  start: element

  element: int | float | string | array | map

  array: ARRAY_START ARRAY_END { result = [] }
       | ARRAY_START array_elements ARRAY_END { result = val[1] }

  map: MAP_START MAP_END { result = {} }
     | MAP_START map_elements MAP_END { result = Hash[val[1]] }

  string: STRING

  int: INT

  float: FLOAT

  array_elements: element { result = [ val[0] ] }
                | array_elements ARRAY_SEP { result = val[0] }
                | array_elements ARRAY_SEP element { result = val[0]; result << val[2] }

  map_elements: element MAP_SEP element { result = [ [ val[0], val[2] ] ]; }
  map_elements: map_elements ARRAY_SEP { result = val[0]; }
  map_elements: map_elements ARRAY_SEP element MAP_SEP element { result = val[0]; result << [ val[2], val[4] ]; }

---- inner

def next_token
  @token = nil
  if !@source.eos?
    case
    when @source.scan(/\(\{\s*/)
      @token = [ :ARRAY_START, '({' ]
    when @source.scan(/\}\)\s*/)
      @token = [ :ARRAY_END, '})' ]
    when @source.scan(/\(\[\s*/)
      @token = [ :MAP_START, '([' ]
    when @source.scan(/\]\)\s*/)
      @token = [ :MAP_END, '])' ]
    when @source.scan(/:\s*/)
      @token = [ :MAP_SEP, ':' ]
    when @source.scan(/,\s*/)
      @token = [ :ARRAY_SEP, ',' ]
    when @source.scan(/(\.\d+|\d+\.(\d+)?)\s*/)
      @token = [ :FLOAT, @source[1].to_f ]
    when @source.scan(/(\d+)\s*/)
      @token = [ :INT, @source[1].to_i ]
    when @source.scan(/"(([^"]+|\\")*)"/)
      @token = [ :STRING, @source[1].sub(/\\"/, '"') ]
    else
      @source.skip_until(/\s/)
      @token = [ :ERROR, '' ]
    end
  end
  @token
end

def parse(text)
  @source = StringScanner.new text.strip
  do_parse
end

def to_mudmode(data)
  if data.is_a?(Integer) || data.is_a?(Float)
    return data.to_s
  elsif data.is_a?(String)
    return '"' + data.gsub("\\", "\\\\").gsub('"', "\\\"").gsub("\t", "\\t").gsub("\n", "\\n").gsub(/[^ -~]+/,'') + '"'
  elsif data.is_a?(Array)
    return "({" + data.map { |d| to_mudmode(d) }.join(",") + "})"
  elsif data.is_a?(Hash)
    # we sort keys so we are consistent across runs - makes testing easier
    return "([" + data.to_a.sort { |a,b| 
      if a[0] < b[0] 
        -1
      elsif a[0] > b[0]
        1
      else
        0
      end
    }.map { |s| to_mudmode(s[0]) + ":" + to_mudmode(s[1]) }.join(",") + "])"
  elsif data.nil?
    return "0"
  else
    return data.class.name
  end
end
