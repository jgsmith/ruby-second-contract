# == Schema Information
#
# Table name: users
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  email         :string(255)
#  password_hash :string(255)
#  settings      :text             default("--- {}\n"), not null
#

require 'bcrypt'

class User < ActiveRecord::Base
  include BCrypt

  validates_presence_of :email, :password_hash
  has_many :characters, inverse_of: :user

  serialize :settings, Hash

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def get_setting(*path)
    settings[path.collect(&:to_s).join(":")]
  end

  def set_setting(*path)
    value = path.pop
    settings[path.collect(&:to_s).join(":")] = value
  end

  def self.user_exists? email
    where(:email => email).count == 1
  end

  def self.set_user_password email, passwd
    user = User.where(:email => email).first_or_create
    user.password = passwd
    user.save!
    user
  end

  def self.authenticate_user email, passwd
    user = where(:email => email).first
    if user.present? && user.password == passwd
      user
    else
      nil
    end
  end
end
