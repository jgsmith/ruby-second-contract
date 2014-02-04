class ItemRelationship < ActiveRecord::Base
  belongs_to :source, class_name: "Item", inverse_of: :item_relationship, polymorphic: true
  belongs_to :target, class_name: "Item", inverse_of: :item_relationship, polymorphic: true

  # we would like an enum or similar if possible
  # otherwise, we'll need to settle for constants :-/

  # target is an item, scene, path, or terrain
  # items/scenes have details as coordinates
  # paths have distance
  # terrains have 2D coordinates
  # paths/terrains also support height above
  @@prepositions = [
    :none,
    :in,
    :worn_by,
    :held_by,
    :on,
    :close,
    :against,
    :under,
    :before,
    :behind,
    :beside,
    :near,
    :over,
  ]

  def preposition
    @@prepositions[read_attribute(:preposition)]
  end

  def preposition= prep
    prep = prep.to_sym
    if @@prepositions.include?(prep)
      write_attribute(:preposition, @@prepositions.indexOf(prep))
    else
      raise "Illegal preposition for relationship: '#{prep.to_s}'"
    end
  end

end