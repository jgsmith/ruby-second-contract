class SecondContract::Game::Hospital
  def initialize domain, data
    @domain = domain
    @zones = data['zones']
    @npcs = data['npcs']
    @groups = data['groups']
    @armorSets = data['armor-sets']
    @armors = data['armors']
    @treasureSets = data['treasure-sets']
    @treasures = data['treasures']
    @inventory = data['inventory']
    @weaponSets = data['weapon-sets']
    @weapons = data['weapons']
  end

  
end