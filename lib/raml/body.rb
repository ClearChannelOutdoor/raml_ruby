module Raml
  class Body
    include Documentable
    include Parent
    include Validation

    MEDIA_TYPE_RE = %r{[a-z\d][-\w.+!#$&^]{0,63}/[a-z\d][-\w.+!#$&^]{0,63}(;.*)?}oi
        
    attr_accessor :media_type, :example

    def initialize(media_type, body_data, root)
      @children = []
      @media_type = media_type

      body_data.each do |key, value|
        case key
        when 'formParameters'
          validate_hash key, value, String, Hash
          value.each do |name, form_parameter_data|
            @children << Parameter::FormParameter.new(name, form_parameter_data)
          end

        when 'schema'
          validate_string :schema, value
          if root.schemas.include? value
            @children << SchemaReference.new(value)
          else
            @children << Schema.new('_', value)
          end

        else
          begin
            send "#{Raml.underscore(key)}=", value
          rescue
            raise UnknownProperty, "#{key} is an unknown property."
          end
        end
      end
      
      validate
    end
    
    def document
      lines = []
      lines << "**%s**:" % @media_type
      lines << "schema path: %s" % @schema if @schema
      lines << "Example:  \n\n%s" % Raml.code_indenter(@example) if @example

      lines.join "  \n"
    end
    
    children_by :form_parameters, :name, Parameter::FormParameter
    
    child_of :schema, [ Schema, SchemaReference ]

    def web_form?
      [ 'application/x-www-form-urlencoded', 'multipart/form-data' ].include? @media_type
    end
    
    private
    
    def validate
      super

      raise InvalidMediaType, 'body media type is invalid' unless media_type =~ Body::MEDIA_TYPE_RE
      
      if web_form?
        raise InvalidProperty, 'schema property can\'t be defined for web forms.' if schema
        raise RequiredPropertyMissing, 'formParameters property must be specified for web forms.' if
          form_parameters.empty?
      end
    end
  end
end
