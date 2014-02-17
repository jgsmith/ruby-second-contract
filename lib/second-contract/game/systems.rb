class SecondContract::Game
end

module SecondContract::Game::Systems
  require 'second-contract/game/systems/traits'
  require 'second-contract/game/systems/skills'
  require 'second-contract/game/systems/details'
  require 'second-contract/game/systems/physicals'
  require 'second-contract/game/systems/counters'
  require 'second-contract/game/systems/resources'
  require 'second-contract/game/systems/flags'

  include SecondContract::Game::Systems::Traits
  include SecondContract::Game::Systems::Skills
  include SecondContract::Game::Systems::Details
  include SecondContract::Game::Systems::Physicals
  include SecondContract::Game::Systems::Counters
  include SecondContract::Game::Systems::Resources
  include SecondContract::Game::Systems::Flags

protected

  def initialize_systems
    initialize_traits
    initialize_skills
    initialize_details
    initialize_physicals
    initialize_counters
    initialize_resources
    initialize_flags
  end
end