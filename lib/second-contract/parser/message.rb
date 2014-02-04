module SecondContract::Parser
end

class SecondContract::Parser::Message
  def initialize
    @errors = []
  end

  def errors?
    !errors.empty?
  end

  def errors
    @errors
  end

  def error msg
    @errors << {
      pos: @scanner.pos,
      error: msg
    }
  end

  def parse msg
    @scanner = StringScanner.new msg

    bits = []
    @errors.clear

    while !@scanner.eos?
      @scanner.scan(/(([^{<]+|{[^{])*)/)
      bits.push @scanner[0]
      if @scanner.scan(/\{\{/)
        if @scanner.scan(/(([^}]+|}[^}])*)/)
          bits << [ :command, @scanner[0] ]
          if @scanner.eos?
            error("End of string reached without closing }}")
          elsif !@scanner.scan(/\}\}/)
            error("Missing closing }}")
          end
        elsif @scanner.scan(/\}\}/)
          # do nothing
        else
          error("Unsure what to do with this...")
        end
      elsif @scanner.scan(/\</)
        @scanner.scan(/([^>]*)/)
        words = @scanner[1].split(/:/)
        if @scanner.eos?
          error("End of string reached without closing >")
        elsif !@scanner.scan(/>/)
          error("Missing closing >")
        end
        if words.length == 1
          case words[0]
          when "this", "actor"
            bits << [ :substitution, words[0].to_sym, :nominative ]
          when "direct", "indirect", "instrument"
            bits << [ :substitution, words[0].to_sym, :nominative ]
          when "nominative"
            bits << [ :substitution, :lastSubstitution, :nominative ]
          when "objective"
            bits << [ :substitution, :lastSubstitution, :objective ]
          when "name"
            bits << [ :substitution, :lastSubstitution, :name ]
          when "possessive-noun"
            bits << [ :substitution, :lastSubstitution, :"possessive-noun" ]
          when "reflexive"
            bits << [ :substitution, :lastSubstitution, :reflexive ]
          when "verb"
            bits << [ :verb, :lastSubstitution, nil ]
          else
            bits << [ :verb, :lastSubstitution, words[0] ]
          end
        elsif words.length == 2
          if %w(this actor direct indirect instrument).include?(words[0])
            if %w(nominative name objective possessive posessive-noun reflexive).include?(words[1])
              bits << [ :substitution, words[0].to_sym, words[1].to_sym ]
            elsif words[1] == "verb"
              bits << [ :verb, words[0].to_sym, nil ]
            else
              bits << [ :verb, words[0].to_sym, words[1] ]
            end
          elsif words[0] == "verb"
            bits << [ :verb, :lastSubstitution, words[1] ]
          end
        end
      end
    end

    bits.reject { |r| r.is_a?(String) && r.length == 0 }
  end
end