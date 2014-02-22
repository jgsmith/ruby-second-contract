class SecondContract::IFLib::Data::Match
  attr_accessor :status

  def initialize
    @singular_objects = []
    @plural_objects = []
  end

  def remove_objects objs
    @singular_objects.reject!{ |ob| objs.include?(ob) }
    @plural_objects.reject!{ |ob| objs.include?(ob) }
  end

  def remove_object obj
    @singular_objects.reject!{ |ob| ob == obj }
    @plural_objects.reject!{ |ob| ob == obj }
  end

  def add_objects match
    match.get_singular_objects.each do |ob|
      @singular_objects << ob unless @singular_objects.include?(ob)
    end
    match.get_plural_objects.each do |ob|
      @plural_objects << ob unless @plural_objects.include?(ob)
    end
    #@singular_objects = (@singular_objects | match.get_singular_objects).uniq
    #@plural_objects = (@plural_objects | match.get_plural_objects).uniq
  end

  def get_singular_objects
    @singular_objects
  end

  def get_plural_objects
    @plural_objects
  end

  def objects
    (@singular_objects | @plural_objects).uniq
  end

  def add_singular_objects objs
    @singular_objects = (@singular_objects | objs).uniq
  end

  def add_plural_objects objs
    @plural_objects = (@plural_objects | objs).uniq
  end

  def replace_objects match
    @singular_objects = match.get_singular_objects
    @plural_objects = match.get_plural_objects
  end

  def success?
    !@singular_objects.empty? || !@plural_objects.empty?
  end
end
