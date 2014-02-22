require 'tsort'

class SecondContract::Game::SortedHash < Hash
  include TSort

  def initialize sort_key
    @sort_key = sort_key
  end

  alias tsort_each_node each_key

  def tsort_each_child node, &block
    if !node.nil? && include?(node)
      node = fetch(node)
      if node.include?(@sort_key)
        node = node.fetch(@sort_key)
      else
        node = nil
      end
    else
      node = nil
    end
    yield node
  end

  def sorted_keys
    key_list = tsort
    key_list.each do |t|
      each_strongly_connected_component_from(t) { |ns|
        if ns.length != 1
          fs = ns.delete_if { |n| Array === n }.sort.join(", ")
          raise TSort::Cyclic.new("cyclic dependencies: #{fs}")
        end
      }
    end
    key_list.reject { |k| k.nil? }
  end
end