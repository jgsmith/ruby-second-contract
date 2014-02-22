class SecondContract::IFLib::Data::Context
  attr_accessor :him, :her, :it, :them, :singular_objects, :plural_objects

  def initialize
    @him = nil
    @her = nil
    @it = nil
    @them = nil
    @singular_objects = []
    @plural_objects = []
    @ordinal = 0
    @number_included = 0
    @singular = true
  end

  def is_plural?
    !@singular
  end

  def update_number(num, singular)
    if @ordinal
      if @ordinal == -1
        return true
      end
      if @ordinal > num
        @ordinal -= num
        return false
      end
      @ignore_rest = true
      return true
    end
    if @number_included
      if @number_included <= num
        @ignore_rest = true
        num = @number_included
        @number_included = 0
        return num
      end
      @number_included -= num
      return num
    end

    if num > 0 && (@singular)
      return true
    end

    return num
  end
end
