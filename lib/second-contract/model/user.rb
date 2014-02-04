class User < ActiveRecord::Base
  validates_presence_of :email, :password
  has_many :characters, inverse_of: :user
end