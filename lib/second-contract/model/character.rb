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
end