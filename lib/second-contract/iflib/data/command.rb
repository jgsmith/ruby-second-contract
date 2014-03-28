module SecondContract::IFLib
  module Data
    class Command
      require 'second-contract/iflib/sys/english'

      def initialize
        @verb = nil
        @adverbs = []
        @direct = []
        @indirect = []
        @instrument = []
        @unparsed_direct = []
        @unparsed_indirect = []
        @unparsed_instrument = []
        @evocation = []
        @topic = []
      end

      def set_verb(v)
        @verb = v
      end

      def add_adverbs(a)
        @adverbs.concat(a)
      end

      def add_direct(d)
        @unparsed_direct << unparse_noun_phrase(d)
        @direct.concat unwind_noun_phrase(d)
      end

      def add_indirect(i)
        @unparsed_indirect << unparse_noun_phrase(d)
        @indirect.concat unwind_noun_phrase(i)
      end

      def add_instrument(i)
        @unparsed_instrument << unparse_noun_phrase(d)
        @instrument.concat unwind_noun_phrase(i)
      end

      def add_evocation(e)
        @evocation << e
      end

      def add_topic(t)
        @topic << t
      end

      def unparse_noun_phrase(phrase, holding = "holding")
        if phrase.is_a?(Array)
          return SecondContract::IFLib::Sys::English.instance.item_list(phrase.map{ |p| unparse_noun_phrase(p) })
        end

        ret = []
        if phrase[:quantifier]
          if phrase[:quantifier][:article]
            ret << phrase[:quantifier][:article]
          end
        end
        if phrase[:adjectives] && !phrase[:adjectives].empty?
          ret << SecondContract::IFLib::Sys::English.instance.item_list(phrase[:adjectives].uniq)
        end
        if phrase[:nominal]
          ret << phrase[:nominal]
        end
        ret.join(" ")
      end

      def execute(actor)
        if !@adverbs.empty?
          effective_adverb = SecondContract::Game.instance.get_effective_adverb(adverbs)
          if effective_adverb.nil?
            # need to spit out an error to actor
            return false
          end
        end

        args = verb_args
        verb_objs = SecondContract::Game.instance.
                      get_verbs(@verb).
                      select{ |v|
                        v.fits_pos_useage?(args) &&
                        v.fits_actor_requirements?(actor) &&
                        v.actions.all?{ |act| actor.ability("#{act}:actor", {this: actor, actor: actor})}
                      }

        verb_objs.each do |verb_obj|
          direct_obs = []
          extra_obs = {}
          if !@direct.empty?
            if verb_obj.direct_types.include?(:exit)
              extra_obs[:exit] = SecondContract::IFLib::Sys::Binder.instance.bind_exit(actor, @direct)
              if !extra_obs[:exit]
                next
              end
            else
              direct_obs = SecondContract::IFLib::Sys::Binder.instance.bind_direct(actor, verb_obj.direct_types, @direct)
              direct_obs = direct_obs.objects.select { |ob|
                verb_obj.actions.all?{ |act| ob.ability("#{act}:direct", {this: ob, actor: actor})}
              }
              if direct_obs.empty?
                next
              end
            end
          end
          indirect_obs = []
          if !@indirect.empty?
            indirect_obs = SecondContract::IFLib::Sys::Binder.instance.bind_indirect(actor, verb_obj.indirect_types, @indirect, direct_obs)
            indirect_obs = indirect_obs.objects.select { |ob|
              verb_obj.actions.all?{ |act| ob.ability("#{act}:indirect", {this: ob, actor: actor, direct: direct_obs})}
            }
            if indirect_obs.empty?
              next
            end
          end
          instrument_obs = []

          adverb = {} # for now


          event_set = actor.build_event_sequence(verb_obj.actions, extra_obs.merge({
            direct: direct_obs || [],
            indirect: indirect_obs || [],
            instrument: instrument_obs || [],
            topic: @topic,
            evocation: @evocation,
            verb: @verb,
            adverb: @adverbs,
            mods: adverb
          }))
          if event_set && SecondContract::Game.instance.run_event_set(event_set)
            return true
          end
        end
        if actor.fail_message.blank?
          actor.fail_message = default_error
        end
        return false
      end

      def verb_args
        args = []
        if !@direct.empty?
          args << :direct
        end
        if !@indirect.empty?
          args << :indirect
        end
        if !@instrument.empty?
          args << :instrument
        end
        args
      end

      def default_error
        bits = [ "You", "can't" ]

        if !@adverbs.empty?
          bits << SecondContract::IFLib::Sys::English.instance.item_list(@adverbs)
        end

        bits << @verb

        if @unparsed_direct.any?
          bits << SecondContract::IFLib::Sys::English.instance.item_list(
            @unparsed_direct
          )
        end
        if @unparsed_indirect.any?
          bits << SecondContract::IFLib::Sys::English.instance.item_list(
            @unparsed_indirect #.group_by{ |i| i[0] }.map{ |p| p.first.to_s + " " + SecondContract::IFLib::Sys::English.instance.item_list(p.last) }
          )
        end
        if !@unparsed_instrument.empty?
          bits << SecondContract::IFLib::Sys::English.instance.item_list(
            @unparsed_instrument #.group_by{ |i| i[0] }.map{ |p| p.first.to_s + " " + SecondContract::IFLib::Sys::English.instance.item_list(p.last) }
          )
        end
        bits.join(" ") + "."
      end

      def unwind_noun_phrase(phrase)
        # { quantifier: {}, adjectives: [], nominal: 'writing',
        #   relation: {
        #     preposition: :behind,
        #     target: { quantifier: {}, adjectives: [], nominal: 'bar'
        #   }
        # }
        # { article: "the", preposition: nil, adjectives: [], nominal: 'bar' },
        # { article: "the", preposition: :on, adjectives: [], nominal: 'writing' },

        if phrase.is_a?(Array)
          phrase.inject([]) { |ps, p| ps.concat(unwind_noun_phrase(p)); ps }
        else

          elements = []
          while phrase.present? && phrase[:relation].present?
            bit = phrase.merge({preposition: phrase[:relation][:preposition]})
            bit.delete(:relation)
            elements << bit
            phrase = phrase[:relation][:target]
          end

          if phrase.present?
            elements << phrase
          end
          [ elements.reverse ]
        end
      end

    end
  end
end