module Gitter

  class Column

    attr_reader :grid, :name, :headers, :attr, :block, :order, :order_desc, :uniq, :map, :html_options

    def initialize grid, name, opts = {}, &block
      @grid, @name, @block = grid, name, block
      @attr = opts.delete(:column){name}
      @order = opts.delete :order
      @order = attr if @order == true
      @order_desc = opts.delete :order_desc
      @uniq = opts.delete :uniq
      @map = opts.delete(:map){true}
      @html_options = opts.delete(:html_options){{}}
      if opts.has_key?(:header) || opts.has_key?(:headers)  # handle :header => false correctly
         header_opts = opts.delete(:header){opts.delete(:headers)}
         @headers = [header_opts].flatten.map do |header_opt|
           case header_opt
           when Hash
             content = header_opt.delete(:content)
             h_opts = header_opt
           else
             content = header_opt
             h_opts = {}
           end
           Header.new grid, content, h_opts.merge(:column => self)
        end
      else
        @headers = [Header.new(grid, name, opts.merge(:column => self))]
      end
    end

    def cells model
      res = if map && Array === model
        model.map{|m| cells m}
      else
        cell model
      end 

      # set consecutively equal cells to nil
      if uniq && Array === res
        current = nil 
        r = res.map do |el|
          if el != current || current.nil?
            current = el
	  else
            nil
	  end 
	end
	r
      else
        res
      end
    end

    def ordered
      d = grid.filtered_driver

      return d unless ordered? 

      desc = case (p = grid.params[:desc])
        when true, 'true' then order_desc || true
        when false, 'false' then false 
        else p 
      end

      case order
      when :cell
        array_sort(d,desc){|model|cell model}
      when Proc
        array_sort(d,desc){|model|grid.eval(order,model)}
      else
        d.order order, desc
      end
    end

    def desc?
      @desc ||= to_boolean grid.params[:desc]
    end

    def ordered?
      @ordered ||= grid.params[:order] == name.to_s
    end

    def link label = nil, params = {}, options = {}
      label ||= headers.first.label
      if @order
        img = order_img_tag(options)
        label = grid.h.content_tag :span, img + label if ordered?
        grid.h.link_to label, order_params.deep_merge(params), options
      else
        label
      end
    end

    def to_s
      "Column(#{name},ordered=#{ordered?},#{headers.size} headers)"
    end

    private

    def order_img_tag opts = {}
      desc_img = opts.delete(:desc_img){'sort_desc.gif'}
      asc_img  = opts.delete(:asc_img){'sort_asc.gif'}
      grid.h.image_tag( desc? ? desc_img : asc_img)
    end

    def to_boolean s
      not (s && s.match(/true|t|1$/i)).nil?
    end

    # if current params contain order for this column then revert direction 
    # else add order_params for this column to current params
    def order_params
      @order_params ||= begin
        p = grid.params.dup
        if ordered?
          p[:desc] = !desc?
        else
          p = p.merge order: name, desc: false 
        end
        grid.scoped_params p
      end
    end

    def cell model
      grid.decorate model
      if block
        content = grid.eval block, model
      else
        model.send(attr) || ''
      end
    end

    def array_sort driver, desc
      arr = driver.scope.map{|model| [yield(model),model]}
      driver.new arr.sort{|a,b| (desc ? -1 : 1)*(a<=>b) }.map{|a|a[1]}
    end
  end

end
