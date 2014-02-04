class SecondContract::Game::Event
  def initialize obj, type, args = {}
    @type = type
    @object = obj
    @args = {}
  end

  def set_arg k, v
    @args[k] = v
  end

  def handle args = {}
    @object.call_event_handler(@type, args.merge(args).merge({this: @object}))
  end
end