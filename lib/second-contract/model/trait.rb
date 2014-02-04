class Trait
  attr_accessor :traits, :skills, :calculations, :qualities, :abilities, :errors

  def initialize tree
    @calculations = {}
    @qualities = {}
    @abilities = {}
    @reactions = {}
    @traits = {}
    @errors = []

    # check that inherited calculations, qualities, etc., aren't conflicting
    inherited = {
      calculations: {},
      qualities: {},
      abilities: {},
      reactions: {}
    }

    tree[:traits].each_pair do |name, trait|
      [:calculations, :qualities, :abilities].each do |type|
        trait.send(type).keys.each do |k|
          if inherited[type].include?(k)
            inherited[type][k] << name
          else
            inherited[type][k] = [ name ]
          end
        end
      end
    end

    [:calculations, :qualities, :abilities].each do |type|
      needs_local_definition = inherited[type].keys.select {|k|
        inherited[type][k].length > 1
      }
      available = self.send(type).keys
      needs_local_definition = needs_local_definition.reject { |k| available.include?(k) }
      if !needs_local_definition.empty?
        @errors.push "The following #{type} are ill-defined: #{needs_local_definition.sort.join(", ")}"
        needs_local_definition.each do |i|
          @errors.push "#{i} (#{type}) is defined in traits #{inherited[type][i].sort.join(", ")}"
        end
      end
    end
  end

  def errors?
    !@errors.empty?
  end
end