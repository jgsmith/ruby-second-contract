class CreateItem < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :type, null: false, default: 'Item'
      t.string :archetype, null: false
      [ :traits, :skills, :stats, :details, :physicals, :counters, :resources ].each do |col|
        t.string col, default: {}.to_yaml
      end
    end
  end
end
