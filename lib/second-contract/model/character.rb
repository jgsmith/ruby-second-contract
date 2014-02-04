class Character < ActiveRecord::Base
  belongs_to :user, inverse_of: :characters
  belongs_to :item, inverse_of: :character, polymorphic: true

  attr_accessor :terminal

  validates_uniqueness_of :name
  validates_uniqueness_of :item

  def emit klass, text
  	if !terminal.nil?
  		terminal.emit klass, text
    end
  end
end