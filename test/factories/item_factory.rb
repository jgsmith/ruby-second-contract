#
# Item
#
require 'factory_girl'

FactoryGirl.define do
  factory :item do
    archetype_name "std:item"
  end

  factory :unnamed_player_item, :parent => :item do
    archetype_name "std:character"
  end

  factory :luggage_item, :parent => :unnamed_player_item do
    after(:create) do |item, evaluator|
      item.set_detail('default:name', 'luggage')
      item.set_detail('default:capName', 'Luggage')
      item.set_physical('position', 'standing')
      item.set_physical('gender', 'male')
      item.save!
    end
  end
end