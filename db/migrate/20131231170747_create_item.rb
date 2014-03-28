class CreateItem < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :archetype_name, null: false
      [ :traits, :skills, :stats, :details, :physicals, :counters, :resources, :flags ].each do |col|
        t.text col, default: {}.to_yaml
      end
    end
  end
end
