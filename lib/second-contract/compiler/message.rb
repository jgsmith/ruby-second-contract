module SecondContract::Compiler
end

class SecondContract::Compiler::Message
  def initialize
    @abnormal_plurals = {
      "moose" => "moose",
      "mouse" => "mice",
      "die" => "dice",
      "index" => "indices",
      "human" => "humans",
      "sheep" => "sheep",
      "fish" => "fish",
      "child" => "children",
      "ox" => "oxen",
      "tooth" => "teeth",
      "deer" => "deer",
      "sphinx" => "sphinges", 
    }
  end

  def format target, parse_tree, objects
    msg = ""
    lastSubstitution = nil

    parse_tree.each do |segment|
      case segment
      when String
        msg << segment
      when Array
        if segment[1] == :lastSubstitution
          subjects = objects[lastSubstitution]
        else
          subjects = objects[segment[1]]
        end
        subjects = [ subjects ] unless subjects.is_a?(Array)
        case segment.first
        when :substitution
          lastSubstitution = segment[1] unless segment[1] == :lastSubstitution
          items = []
          case segment.last
          when :nominative
            items = subjects.inject([]) { |l, i|
              if i == target
                l << "you"
              else
                l << nominative(i)
              end
            }
          when :objective
            if subjects.include?(target)
              items = [ 'you' ]
              subjects = subjects - [ target ]
            end
            items << objective(subjects)
          when :reflexive
            if subjects.include?(target)
              items = [ 'yourself' ]
              subjects = subjects - [ target ]
            end
            items << reflexive(subjects)
          when :"possessive-noun"
            if subjects.include?(target)
              items = [ 'your' ]
              subjects = subjects - [ target ]
            end
            items << possessive_noun(subjects)
          when :name
            items = subjects.inject({}) { |l, i|
              if i == objects[:this]
                l << "you"
              else
                l << i.trait('name')
              end
            }
          end
          msg << item_list(items.compact)
        when :verb
          # segment[1] == pos using verb
          # segment[2] == plural verb form
          if subjects.length == 1
            if subjects.include?(target)
              msg << segment[2]
            else
              msg << pluralize(segment[2])
            end
          else
            msg << segment[2]
          end
        end
      end
    end
    msg.strip!
    msg[0..0] = msg[0..0].upcase
    msg
  end

  def item_list items
    if items.nil?
      "nothing"
    else
      items = [ items ] unless items.is_a?(Array)
      if items.length == 0
        "nothing"
      else
        list = items.inject({}) do |l, item|
          if !item.is_a?(String)
            if item.is('living')
              item = item.trait('name')
            else
              item = item.trait('title')
            end
          end
          if l.include?(item)
            l[item] += 1
          else
            l[item] = 1
          end
          l
        end
        items = list.keys.sort { |a, b|
          a.sub(/^(an?|the)\b/i,'') <=> b.sub(/^(an?|the)\b/i,'')
        }
        if items.length == 0
          "nothing"
        else
          str = ""
          str << consolidate(list[items.first], items.first)
          if items.length > 1
            if items.length > 2
              str << ","
            end
            items.drop(1).each_with_index do |item, idx|
              if idx == items.length-2
                str << " and "
              else
                str << " "
              end
              str << consolidate(list[item], item)
              if idx < items.length-2
                str << ","
              end
            end
          end
          str
        end
      end
    end
  end

  def pluralize str
    if str.nil?
      return str
    end
    if @abnormal_plurals[str]
      return @abnormal_plurals[str]
    end
    len = str.length
    if len > 1
      case str[len-2..len-1]
      when "ch", "sh"
        return str + "es"
      when "ff", "fe"
        return str[0..len-3] + "ves"
      when "us"
        return str[0..len-3] + "i"
      when "um"
        return str[0..len-3] + "a"
      when "ef"
        return str + "s"
      end
    end
    case str[len-1..len-1]
    when "o", "x", "s"
      return str + "es"
    when "f"
      return str[0..len-2] + "ves"
    when "y"
      if %w(a e i o u).include?(str[len-2..len-2])
        return str + "s"
      else
        return str[0..len-2] + "ies"
      end
    end
    return str + "s"
  end

  def consolidate count, str
    if count == 1
      str
    else
      words = str.split(/\s+/)
      if words.last =~ /^\((.*)\)$/
        tmp = $1
        if words.length == 1
          "(" + consolidate(count, tmp) + ")"
        else
          consolidate(count, words[0..words.length-2].join(" ")) + " (#{tmp})"
        end
      elsif words.last =~ /^\[(.*)\]$/
        tmp = $1
        if words.length == 1
          "[" + consolidate(count, tmp) + "]"
        else
          consolidate(count, words[0..words.length-2].join(" ")) + " [#{tmp}]"
        end
      elsif %w(a an the one).include?(words.first.downcase)
        if count == 0
          "no " + pluralize(words.drop(1).join(" "))
        else
          cardinal(count) + " " + pluralize(words.drop(1).join(" "))
        end
      elsif count == 0
        "no " + pluralize(words.join(" "))
      else
        cardinal(count) + " " + pluralize(words.join(" "))
      end
    end
  end

  @@number_words = %w(
    zero one two three four five six seven eight nine 
    ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen
    twenty
  )

  @@decade_words = %w(
    error error twenty thirty forty fifty sixty seventy eighty ninety
  )

  def cardinal x = 0
    if !x
      "zero"
    elsif x < 0
      "negative " + cardinal(-x)
    elsif x < 21
      @@number_words[x]
    elsif x > 1000000000
      "over a billion"
    elsif (a = (x / 1000000).to_i) != 0
      if (x = x % 1000000) != 0
        cardinal(a) + " million " + cardinal(x)
      else
        cardinal(a) + " million"
      end
    elsif (a = (x / 1000).to_i) != 0
      if (x = x % 1000) != 0
        cardinal(a) + " thousand " + cardinal(x)
      else
        cardinal(a) + " thousand"
      end
    elsif (a = (x / 100).to_i) != 0
      if (x = x % 100) != 0
        cardinal(a) + " hundred " + cardinal(x)
      else
        cardinal(a) + " hundred"
      end
    else
      a = (x / 10).to_i
      if (x = x % 10) != 0
        tmp = "-" + cardinal(x)
      else
        tmp = ""
      end
      if a > 1 && a < 10
        @@decade_words[a] + tmp
      else
        "error"
      end
    end
  end

  def possessive_noun item
    case item
    when nil
      "its"
    when Array
      if item.length == 1
        possessive_noun(item.first)
      elsif item.length == 0
        ""
      else
        "their"
      end
    when String
      case item[item.length-1..item.length-1]
      when "x", "z", "s"
        item + "'"
      else
        item + "'s"
      end
    else
      item = item.trait('name')
      if !item
        "its"
      else
        possessive_noun(item)
      end
    end
  end

  def nominative item
    case item
    when nil
      ""
    when Array
      if item.length == 1
        nominative item.first
      elsif item.length == 0
        ""
      else
        "they"
      end
    when String
      item
    else
      case item.trait("body:gender")
      when "male"
        "he"
      when "female"
        "she"
      when "neutral"
        "hi"
      else
        "it"
      end
    end
  end

  def objective item
    case item
    when nil
      ""
    when Array
      if item.length == 1
        objective item.first
      elsif item.length == 0
        ""
      else
        "them"
      end
    when String
      item
    else
      case item.trait("body:gender")
      when "male"
        "him"
      when "female"
        "her"
      when "neutral"
        "hir"
      else
        "it"
      end
    end
  end

  def possessive item
    case item
    when nil
      ""
    when Array
      if item.length == 1
        possessive item.first
      elsif item.length == 0
        ""
      else
        "their"
      end
    when String
      item
    else
      case item.trait("body:gender")
      when "male"
        "his"
      when "female"
        "her"
      when "neutral"
        "hir"
      else
        "its"
      end
    end
  end

  def reflexive item
    case item
    when nil
      ""
    when Array
      if item.length == 1
        reflexive item.first
      elsif item.length == 0
        ""
      else
        "themselves"
      end
    when String
      item
    else
      case item.trait("body:gender")
      when "male"
        "hisself"
      when "female"
        "herself"
      when "neutral"
        "hirself"
      else
        "itself"
      end
    end
  end
end