#
# ItemDetail
#
require 'factory_girl'

FactoryGirl.define do
  factory :item_detail do
  end

  factory :old_seadog_default_detail, :parent => :item_detail do
    after(:create) do |item, evaluator|
      item.item =  Domain.find_by(:name => 'start').items.where(:name => 'scene:start').first
      item.coord = 'default'
    end
  end

  factory :old_seadog_bar_detail, :parent => :old_seadog_default_detail do
    after(:create) do |item, evaluator|
      item.coord = 'bar'
    end
  end
end