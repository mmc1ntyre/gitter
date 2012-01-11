module TracksGrid

  class Column
    attr_reader :spec, :grid

    delegate :name, :to => :spec
    delegate :params, :to => :grid

    def initialize( spec, grid )
      @spec, @grid = spec, grid
    end

    def cell( model, decorator_class = nil )
      if spec.block
        Decorator.decorate model, decorator_class, :h => grid.view_context
        model.instance_eval &spec.block
      else
        model.send name
      end
    end

    def ordered
      spec.ordered grid.scope, params[:desc]
    end

    def header
      @header ||= grid.eval spec.header
    end

    # if current params contain order for this column then revert direction 
    # else add order_params for this column to current params
    def order_params
      @order_params ||= begin
        p = params.dup
        if ordered?
          p[:desc] = !desc?
        else
          p = p.merge :order => name, :desc => false 
        end
        p
      end
    end

    def desc?
      @desc ||= to_boolean params[:desc]
    end

    def ordered?
      @ordered ||= params[:order] == name.to_s
    end

    def link( opts = {} )
      if spec.ordered?
        direction = ordered? ? (col.desc? ? '^' : 'v') : ''
        grid.h.link_to "#{direction} #{header}" , order_params.merge(opts)
      else
        header 
      end 
    end

    private

    def to_boolean(s)
      not (s && s.match(/true|t|1$/i)).nil?
    end
  end

end
