class CreateItemRelationships < ActiveRecord::Migration
  def change
    create_table :item_relationships do |t|
      t.references :source
      t.references :target
      t.integer    :preposition, default: 0
      t.string     :detail, default: 'default'  # for scenes
      t.integer    :x       # for paths and surfaces/terrains
      t.integer    :y       # for terrains
      t.boolean    :hidden, :null => false, :default => false # used when logged out
    end
  end
end
