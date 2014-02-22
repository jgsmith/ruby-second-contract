class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password
      t.text   :settings, :null => false, :default => {}.to_yaml
    end
  end
end
