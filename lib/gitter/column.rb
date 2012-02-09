module Gitter

  class Column
    attr_reader :spec, :grid

    def initialize grid, spec 
      @grid, @spec = grid, spec
    end

    def name
      spec.name
    end

    def params
      grid.params
    end

    def cell model
      if spec.block
        grid.eval spec.block, model
      else
        model.send spec.attr
      end
    end

    def ordered
      d = grid.filtered_driver

      return d unless ordered?

      desc = case params[:desc]
        when true, 'true' then spec.order_desc || true
        when false, 'false' then false 
        else params[:desc]
      end

      if Proc === spec.order
        arr = d.scope.map{|model| [model.instance_eval(&spec.order),model]}
        d.new arr.sort{|a,b| (desc ? -1 : 1)*(a<=>b) }.map{|a|a[1]}
      else
        d.order spec.order, desc
      end
    end

    def headers
      @headers ||= spec.header_specs.map{|spec| Header.new grid, spec, :column => self}
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

    def link label = nil, params = {}, opts = {}
      label ||= headers.first.label
      if spec.ordered?
        img = order_img_tag(opts)
        label = h.content_tag :span, img + label if ordered?
        h.link_to label, order_params.merge(params), opts
      else
        label
      end
    end

    def to_s
      "Column(#{name},ordered=#{ordered?})"
    end

    private

    def order_img_tag opts = {}
      desc_img = opts.delete(:desc_img){'sort_desc.gif'}
      asc_img  = opts.delete(:asc_img){'sort_asc.gif'}
      h.image_tag( desc? ? desc_img : asc_img)
    end

    def h
     grid.h
    end

    def to_boolean s
      not (s && s.match(/true|t|1$/i)).nil?
    end
  end

end