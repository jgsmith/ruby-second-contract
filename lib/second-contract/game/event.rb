class SecondContract::Game::Event
  attr_accessor :type

  def initialize obj, type, args = {}
    @type = type
    @object = obj
    @args = args
  end

  def set_arg k, v
    @args[k] = v
  end

  def handle args = {}
    @object.call_event_handler(@type, args.merge(@args).merge({this: @object}))
  end
end