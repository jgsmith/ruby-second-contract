require 'second-contract/parser/script'
require 'second-contract/model/archetype'
require 'second-contract/model/item_detail'
require 'second-contract/iflib/sys/binder'

describe ItemDetail do
  subject(:old_seadog_bar) { FactoryGirl.create(:old_seadog_bar_detail) }

  it "should be in the old seadog default detail" do
    expect(old_seadog_bar.physical('environment').coord).to eq 'default'
    expect(old_seadog_bar.physical('environment').item).to eq old_seadog_bar.item
    expect(old_seadog_bar.describe_detail).to eq 'The bar is polished.'
    expect(old_seadog_bar.item.describe_detail(key: 'bar')).to eq 'The bar is polished.'
  end
end
