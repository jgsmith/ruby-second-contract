class Domain < ActiveRecord::Base
  has_many :items

  validates_uniqueness_of :name
  validates_presence_of :name

  def get_item(nom)
    items.where(:name => nom).first
  end

  #
  # we need to load in information from the data file...
  # and make sure we have the right items created (e.g., scenes)
  #
  def load_map(data)
    if data['guards']
      data['guards'].each_pair do |name, info|
        load_item('guard', name, info)
      end
    end

    if data['scenes']
      data['scenes'].each_pair do |name, info| 
        load_item('scene', name, info)
      end
    end
  end

  def load_hospital(data)
  end

private

  def load_item(type, name, info)
    item = Item.where(:name => "#{type}:#{name}", :domain => self).first
    if item.nil?
      item = Item.create({ :name => "#{type}:#{name}", :domain => self })
    end
    if info['archetype']
      ur = SecondContract::Game.instance.get_archetype(info['archetype'])
      if ur
        item.archetype = ur
      else
        item.archetype_name = info['archetype']
      end
    end
    if info['flags']
      info['flags'].each do |flag|
        if flag.match(/^not?-(.*)/)
          item.set_flag($1, false)
        else
          item.set_flag(flag, true)
        end
      end
    end

    if info['traits']
      flatten_hash(info['traits']).each_pair do |k, v|
        item.set_trait(k, v)
      end
    end

    if info['details']
      flatten_hash(info['details']).each_pair do |k, v|
        item.set_detail(k, v)
      end
    end

    if info['counters']
      flatten_hash(info['counters']).each_pair do |k, v|
        item.set_counter(k, v)
      end
    end

    if info['physicals']
      flatten_hash(info['physicals']).each_pair do |k, v|
        item.set_physical(k, v)
      end
    end

    if info['resources']
      flatten_hash(info['resources']).each_pair do |k, v|
        item.set_resource(k, v)
      end
    end

    if info['skills']
      flatten_hash(info['skills']).each_pair do |k, v|
        item.set_skill(k, v)
      end
    end

    item.save!
  end

  def flatten_hash(hash)
   hashKeys = hash.keys.select{|k| hash[k].is_a?(Hash)}
    while hashKeys.count > 0
      hashKeys.each do |parent|
        hash[parent].each do |k,v|
          hash[parent + ":" + k] = v
        end
        hash.delete parent
      end
      hashKeys = hash.keys.select{|k| hash[k].is_a?(Hash)}
    end
    hash
  end


end