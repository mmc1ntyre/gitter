module TracksGrid

  class FacetValue

    attr_reader :facet, :value, :count

    def initialize( facet, value, count )
      @facet, @value, @count = facet, value, count 
      puts to_s
    end

    def params
      { name => value }
    end

    def name
      facet.name
    end

    def to_s
      "#{name}:#{value}=#{count}"
    end
  end

  class Facet

    attr_reader :filter, :scope

    def initialize( filter, scope )
      @filter, @scope = filter, scope
    end

    def count
      filter.counts scope
    end

    def values
      values = [] 
      count.each do |value, count|
        values << FacetValue.new(self, value, count)
      end
      values
    end

    def name
      filter.name
    end

    def label
      filter.label
    end

    def to_s
      "#{self.class}(#{name},#{label})"
    end

  end

end
