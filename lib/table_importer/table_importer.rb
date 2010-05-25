

# core extension 
# if we are in a non Rails Environment we need to constantize a String

unless "foo".respond_to?(:constantize)
  class String
    def constantize
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ self
        raise NameError, "#{self.inspect} is not a valid constant name!"
      end
      Object.module_eval("::#{$1}", __FILE__, __LINE__)
    end
  end
end



module TableImporter
  class Importer
    attr_accessor :mapper, :data

    def initialize(data=nil,mapper=nil)
      @data = data
      @mapper = mapper
    end

    def build
      @data.map { |row| build_row(row) }
    end

    def build_object_for_attributes(klass_name, attributes, row)
      object = klass_name.constantize.new
      attributes[:attributes].each do |attr, value|

        vals = Array(value).map do |v|
          if v.is_a? Symbol
            row[@mapper.get_column_number(v)]
          else
            v
          end
        end

        val = get_value(* vals)
        object.send("#{attr}=", val)
        build_reflections_for_object(attributes[:reflections], object, row) if attributes[:reflections]
      end
      object
    end

    def build_row(row)
      @mapper.klasses.keys.map do |klass_name|
        build_object_for_attributes(klass_name, @mapper.klasses[klass_name], row)
      end
    end


    def build_reflections_for_object(reflections, object, row)
      reflections.each do |reflection_name, reflection|
        if reflection[:macro] == :has_many
          collection = reflection[:attributes].inject([]){|a,v| v.last.size.times{|i| a[i]||={:attributes=>{}};a[i][:attributes].merge! ({v.first=>v.last[i]}) } ;a }.map do |attributes|
            build_object_for_attributes(reflection[:class_name], attributes, row)
          end
          object.send("#{reflection_name}=",collection)
        else
          object.send("#{reflection_name}=", build_object_for_attributes(reflection[:class_name], reflection, row))
        end
      end
      object
    end


    def get_value(* args)
      if args.size > 1
        if args.last.is_a? Proc
          block = args.pop
          block.call(* args)
        else
          args
        end
      else
        args.first
      end
    end
  end


  class Mapper
    attr_reader :klasses

    def get_attributes_for_class(klass_name, dict)

      attributes = {}
      attributes[:attributes] = {}

      dict.each do |attr, value|
        if value.is_a?(Hash) # reflection
          reflected_klass = klass_name.constantize
          macro = reflected_klass.reflections[attr].macro
          class_name = reflected_klass.reflections[attr].class_name
          attributes[:reflections] ||= {}
          attributes[:reflections].merge!(attr=>{:macro=>macro, :class_name=>class_name})
          attributes[:reflections][attr].merge! get_attributes_for_class(class_name, value)
        else
          attributes[:attributes][attr] = value
        end
      end
      attributes
    end

    def initialize(dictonary)
      @dictonary = dictonary
      @klasses = {} #
      dictonary.each do |klass, dict|
        @klasses[klass] = get_attributes_for_class(klass, dict)
      end
    end


    def get_column_number(col)
      col = col.to_s[/^col_?([A-Za-z]+|\d+)$/, 1]
      if col.to_i == 0
        col =col.split(//).inject(-25) { |i, w| i += (("A".."Z").to_a.index(w) || ("a".."z").to_a.index(w)) +26 }
      end
      col.to_i-1

    end
  end
end