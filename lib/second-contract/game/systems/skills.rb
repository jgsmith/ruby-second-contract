module SecondContract::Game::Systems::Skills
  ##
  # A skill is a bundle of related values that indicate how well an object/player
  # can perform some task. A skill has the following components:
  #
  #   :value - the primary number used in performing a skills test
  # 

  def skill(name, objs = {})
    bits = name.split(/:/)
    if bits.length == 1
      bits << 'value'
    end
    if bits.length > 2
      nil
    else
      if skills.include?(bits[0]) && skills[bits[0]].include?(bits[1])
        skills[bits[0]][bits[1]]
      elsif archetype
        archetype.skill(name)
      else
        0
      end
    end
  end

  def set_skill name, val, objs = {}
    val = val.try(to_i)
    if val.is_a?(Fixnum) && val > 0 && validate(:skill, name, val, objs)
      bits = name.split(/:/)
      if bits.length == 1
        bits << 'value'
      end
      if !skills.include?(bits[0])
        skills[bits[0]] = {}
      end
      skills[bits[0]][bits[1]] = val
    end
  end

  ##
  # skill_defense_for(skill) -> skill
  #
  # Returns the appropriate skill to use when defending against the given skill.
  #
  # This is the skill usually used by the defender of an attack.
  #
  def skill_defense_for skill
    case skill
    when "striking"
      "blocking"
    when "following"
      "evading"
    else
      if skill.end_with?("-defense")
        skill[0..skill.length-8]
      else
        skill + "-defense"
      end
    end
  end

  ##
  # skill_aid_for(skill) -> skill
  #
  # Returns the appropriate skill to use when aiding the use of the given skill.
  #
  # This is the skill usually used by an isntrument or other object being used by
  # an attacker in an attack (e.g., a sword), or a defender in defense (e.g., a shield).
  #
  def skill_aid_for skill
    
  end

protected

  def initialize_skills
  end
end