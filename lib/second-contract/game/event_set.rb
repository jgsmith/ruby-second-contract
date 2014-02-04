class SecondContract::Game::EventSet
  def initialize
    @forward_guards = []
    @backward_guards = []
    @forward_consequents = []
    @backward_consequents = []
    @forward_reactions = []
    @backward_reactions = []
    @next_set = nil
    @previous_set = nil
    @forward_guards_run = false
  end

  def set_next_set e
    if @next_set
      e.set_next_set @next_set
    end
    e.set_previous_set self
    @next_set = e
  end

  def set_previous_set e
    if @previous_set
      @previous_set.set_next_set e
    end
    e.set_next_set self
    e.set_previous_set @previous_set
    @previous_set = e
  end

  def get_guards f
    f ? @forward_guards : @backward_guards
  end

  def add_guard g
    @forward_guards.push g
    @forward_guards.compact!
  end

  def wrap_guards f, b
    @forward_guards.push f
    @backward_guards.push b
    @forward_guards.compact!
    @backward_guards.compact!
  end

  def get_consequents f
    f ? @forward_consequents : @backward_consequents
  end

  def add_consequent c
    @forward_consequents.push c
    @forward_consequents.compact!
  end

  def wrap_consequents f, b
    @forward_consequents.push f
    @backward_consequents.push b
    @forward_consequents.compact!
    @backward_consequents.compact!
  end

  def get_reactions f
    f ? @forward_reactions : @backward_reactions
  end

  def add_reaction e
    @forward_reactions.push e
    @forward_reactions.compact!
  end

  def wrap_reactions f, b
    @forward_reactions.push f
    @backward_reactions.push b
    @forward_reactions.compact!
    @backward_reactions.compact!
  end

  def run_guards f
    event_manager = SecondContract::Game.instance
    g = get_guards f
    added_sets = 0
    if g.empty?
      true
    else
      g.each do |e|
        ret = event_manager.call_event e
        case ret
        when FalseClass
          return false
        when Array
          if @forward_guards_run or not f
            return false
          end
          added_sets += ret.length
          ret.reverse_each do |r|
            set_previous r
          end
        end
      end
      if f
        @forward_guards_run = true
      end
      added_sets > 0 ? added_sets : true
    end
  end
end