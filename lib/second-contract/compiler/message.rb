module SecondContract::Compiler
end

class SecondContract::Compiler::Message
  require 'second-contract/iflib/sys/english'

  def format target, parse_tree, objects
    msg = ""
    lastSubstitution = nil
    pronouns = {}
    objects = {}.merge(objects)
    objects[:this] = target

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
          when :nominative_
            items = subjects.inject([]) { |l, i|
              if i == target
                l << "you"
              else
                l << SecondContract::IFLib::Sys::English.instance.nominative(i)
              end
            }
          when :objective
            if subjects.include?(target)
              items = [ 'you' ]
              subjects = subjects - [ target ]
            end
            items << SecondContract::IFLib::Sys::English.instance.objective(subjects)
          when :reflexive
            if subjects.include?(target)
              items = [ 'yourself' ]
              subjects = subjects - [ target ]
            end
            items << SecondContract::IFLib::Sys::English.instance.reflexive(subjects)
          when :"possessive-noun"
            if subjects.include?(target)
              items = [ 'your' ]
              subjects = subjects - [ target ]
            end
            items << SecondContract::IFLib::Sys::English.instance.possessive_noun(subjects)
          when :name, :nominative
            items = subjects.inject([]) { |l, i|
              if i == objects[:this]
                l << "you"
              else
                l << i
              end
            }
          end
          msg << SecondContract::IFLib::Sys::English.instance.item_list(items.compact)
        when :verb
          # segment[1] == pos using verb
          # segment[2] == plural verb form
          if subjects.length == 1
            if subjects.include?(target)
              msg << segment[2]
            else
              msg << SecondContract::IFLib::Sys::English.instance.pluralize(segment[2])
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
end