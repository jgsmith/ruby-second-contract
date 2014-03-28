class ItemDetail
  attr_accessor :item, :coord, :preposition

  delegate :counter, :flag, :resource, :skill, :trait, :to => :item

  def initialize(item = nil, detail = 'default', preposition = 'in')
    @item = item
    @coord = detail
    @preposition = preposition
  end

  def ==(comparison_object)
    super ||
      comparison_object.instance_of?(self.class) &&
      @item == comparison_object.item &&
      @coord == comparison_object.coord &&
      @preposition == comparison_object.preposition ||
      comparison_object.instance_of?(Item) &&
      @item == comparison_object &&
      @coord == 'default' &&
      @preposition == 'in'
  end

  alias :eql? :==

  def inspect
    if @preposition == 'in'
      "#{@item.inspect}:#{@coord}"
    else
      "#{@preposition}:#{@item.inspect}:#{@coord}"
    end
  end

  def describe_detail key: 'default', sense: 'sight', seasons: [], times: [], objs: {}
    if key == 'default'
      key = @coord
    end

    @item.describe_detail(key: key, sense: sense, seasons: seasons, times: times, objs: objs.merge({this: @item}))
  end

  def detail_exits key: 'default', objs: {}
    if key == 'default'
      key = @coord
    end

    @item.detail_exits(key: key, objs: objs)
  end

  def related_sources(preps = nil)
    @item.related_source_details(preps, @coord)
  end

  def related_targets(preps = nil)
    # look for any related items that have a relationship in preps
    # these will all be details in the item
    @item.related_target_details(preps, @coord)
  end

  def detail(key, objs = {})
    bits = key.split(/:/)
    if bits.first == 'default'
      bits[0] = @coord
    end
    key = bits.join(':')
    @item.detail(key, objs)
  end

  def physical(key, objs = {})
    if key == 'location' && coord != 'default'
      info = @item.get_all_detail(@coord, objs)
      info.select do |k, v|
        k.start_with?('related-to:')
      end.each_pair do |p, pt|
        return ItemDetail.new(@item, pt, p.split(/:/)[1])
      end
      return @item
    end
    if key == 'environment' && @coord != 'default'
      # what's this detail in in the item?
      details = [ @coord ]
      while !details.empty?
        info = @item.get_all_detail(details.pop, objs)
        # we follow the related-tos until we find something we're 'in'
        info.select do |k, v| 
          k.start_with?('related-to:')
        end.group_by do |p|
          p.first.split(/:/)[1]
        end.each do |prep, prepInfo|
          if prep == 'in'
            return ItemDetail.new(@item, prepInfo.first.last, prep)
          else
            details.concat prepInfo.collect {|p| p.last }.flatten
          end
        end
      end
      # if we haven't found an 'in' by now, then we're 'in' the default detail
      return @item
    else
      @item.physical(key, objs)
    end
  end

  def trigger_event evt, objs
    SecondContract::Game.instance.call_event(
      SecondContract::Game::Event.new(@item, evt, objs.merge({this: @item, detail: @coord}))
    )
  end

  def has_event_handler? evt
    @item.has_event_handler? evt
  end

  def call_event_handler evt, args
    @item.call_event_handler(evt, args.merge({detail: @coord}))
  end

  def quality name, objs = {}
    @item.quality(name, objs.merge({detail: @coord}))
  end

  def ability name, objs = {}
    @item.ability(name, objs.merge({detail: @coord}))
  end

  ###
  ### Parser support - only in items
  ###
  def parse_command_id_list
    ids = detail('default:noun', {this: self}) || []
    ids << detail('default:name')
    ids.compact.uniq
  end

  # TODO: make pluralize a static method or a method on String
  #
  def parse_command_plural_id_list
    parse_command_id_list.map {|id|
      SecondContract::IFLib::Sys::English.instance.pluralize(id)
    }
  end

  def parse_command_adjective_id_list
    detail('default:adjective', {this: self})
  end

  def parse_command_plural_adjective_id_list
    parse_command_adjective_id_list
  end

  def parse_match_object(input, actor, context)
    ret = is_matching_object(input, actor, context)
    if ret.empty?
      [ :no_match, [] ]
    elsif !context.update_number(1, ret)
      nil
    else
      [ ret, [ self ] ]
    end
  end

  def is_visible_to(actor)
    true
  end

  def is_matching_object(input, actor, context)
    objs = { this: self, actor: actor }
    last_bit = input[:nominal]
    ret = []
    case last_bit
    when "him"
      if self == context.him
        ret << :singular
      end
    when "her"
      if self == context.her
        ret << :singular
      end
    when "it"
      if self == context.it
        ret << :singular
      end
    when "them"
    when "me"
      if self == actor
        ret << :singular
      end
    when "all", "things", "ones"
    when "thing", "one"
      ret << :singular
    end

    env = self.physical("environment", objs)
    if ret.empty?
      if parse_command_id_list.include?(last_bit)
        ret << :singular
      elsif parse_command_plural_id_list.include?(last_bit)
        ret << :match_plural
      end
    end

    # now match adjectives
    if !ret.empty? && input.length > 0
      adj = parse_command_adjective_id_list
      padj = parse_command_plural_adjective_id_list
      if env == actor.physical("environment")
        adj |= [ "here" ]
        padj |= [ "here" ]
      end
      if env == context.him
        adj |= [ "his" ]
      end
      if env == context.her
        adj |= [ "her" ]
      end
      if env == context.it
        adj |= [ "its" ]
      end
      if env == actor
        adj |= [ "my" ]
      end
      if context.is_plural? && context.plural_objects.include?(env)
        adj |= [ "their" ]
      end

      if !input[:adjectives].all? { |a| adj.include?(a) }
        if !input[:adjectives].all? { |a| padj.include?(a) }
          return []
        else
          ret -= [ :singular ]
          ret |= [ :match_plural ]
        end
      end
    end

    ret
  end
  def save!
    # no op
  end
end