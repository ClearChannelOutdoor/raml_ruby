module Raml
  class Method < AbstractMethod
    NAMES = %w(options get head post put delete trace connect patch)

    def initialize(name, method_data, root)
      is = method_data.delete('is') || []

      super

      validate_array :is, is, [String, Hash]

      @children += is.map do |trait|
        if trait.is_a? Hash
          if trait.keys.size == 1 and root.traits.include? trait.keys.first
            raise InvalidProperty, 'is property with map of trait name but params are not a map' unless 
              trait.values[0].is_a? Hash
            TraitReference.new( *trait.first )
          else
            Trait.new '_', trait, root
          end
        else
          TraitReference.new trait
        end
      end
    end

    children_of :traits, [ Trait, TraitReference ]

    private

    def validate
      raise InvalidMethod, "#{@name} is an unsupported HTTP method" unless NAMES.include? @name
      super
    end
  end
end