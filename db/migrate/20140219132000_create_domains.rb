class CreateDomains < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.string :name
    end

    add_column :items, :domain_id, :integer
    add_column :items, :name, :string, :limit => 64
    add_column :items, :transient, :boolean, :null => false, :default => false
  end
end
