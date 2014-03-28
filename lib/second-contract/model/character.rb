# == Schema Information
#
# Table name: characters
#
#  id      :integer          not null, primary key
#  name    :string(255)
#  item_id :integer
#  user_id :integer
#

class Character < ActiveRecord::Base
  belongs_to :user, inverse_of: :characters
  belongs_to :item, inverse_of: :character

  validates_uniqueness_of :name
  validates_uniqueness_of :item

  def bind(term)
    SecondContract::Game.instance.bind(self.item, term)
  end

  def unbind
    # we need to freeze our item
  end

  def self.character_exists? name
    # this is a bit more difficult because the character is an object in the game
    #
    where(:name => name.downcase).count == 1
  end

  def self.create_character user, info
    # we want to create an item and connect it to a character object
    # that is connected to the logged in user
    #ActiveRecord::transaction do
    if user.characters.count < 5
      start_loc = SecondContract::Game.instance.get_start_location

      if start_loc.nil?
        puts "*** Start location is not found - aborting character creation"
        return false
      end

      char = nil
      user.transaction(:requires_new => true) do
        item = Item.create(
          archetype_name: info[:archetype]
        )
        item.set_detail('default:name', info[:name].downcase, { this: item })
        item.set_detail('default:capName', info[:capname], { this: item })
        item.set_physical('gender', info[:gender], { this: item })
        item.save!
        item.do_move_to_location('start', start_loc)
        item.set_physical('position', 'standing', { this: item })
        item.save!
        char = user.characters.create!({
          name: info[:name].downcase,
          item: item
        })
      end
      char
    end
  end
end
