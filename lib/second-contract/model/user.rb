class User < ActiveRecord::Base
  validates_presence_of :email, :password
  has_many :characters, inverse_of: :user

  serialize :settings, Hash

  def get_setting(*path)
    settings[path.collect(&:to_s).join(":")]
  end

  def set_setting(*path)
    value = path.pop
    settings[path.collect(&:to_s).join(":")] = value
  end
end