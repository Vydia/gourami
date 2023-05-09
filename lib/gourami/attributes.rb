module Gourami
  module Attributes

    module ClassMethods

      # Copy parent attributes to inheriting class.
      #
      # @param klass [Class]
      def inherited(klass)
        super(klass)
        klass.instance_variable_set(:@attributes, attributes.dup)
        klass.instance_variable_set(:@default_attribute_options, default_attribute_options.dup)
      end

      # Define an attribute for the form.
      #
      # @param name
      #   The Symbol attribute name.
      # @option options
      #   The type of this attribute. Can be any of :string, :integer,
      #   :float, :array, :hash or :boolean.
      # @block default_block
      #   If provided, the block will be applied to options as the :default
      def attribute(name, options = {}, &default_block)
        base = self
        options = options.dup
        options[:default] = default_block if block_given?

        options_with_defaults = merge_default_attribute_options(options)

        mixin = Module.new do |mixin|
          unless options_with_defaults[:skip_reader]
            if !base.attributes.key?(name) && base.instance_methods.include?(name) && !options_with_defaults[:override_reader]
              raise AttributeNameConflictError, "#{name} is already a method. To use the existing method, use `:skip_reader => true` option. To override the existing method, use `:override_reader => true` option."
            end

            mixin.send(:define_method, :"#{name}") do
              value = instance_variable_get(:"@#{name}")
              default = options_with_defaults[:default]

              if value.nil? && default
                default.respond_to?(:call) ? instance_exec(&default) : default
              else
                value
              end
            end
          end

          # Define external setter.
          mixin.send(:define_method, :"#{name}=") do |value|
            provided_attributes_names[name.to_s] = options
            send(:"_#{name}=", value)
          end

          # Define internal setter.
          mixin.send(:define_method, :"_#{name}=") do |value|
            instance_variable_set(:"@#{name}", setter_filter(name, value, self.class.merge_default_attribute_options(options)))
          end
          mixin.send(:private, :"_#{name}=")

          case options[:type]
          when :boolean
            mixin.send(:define_method, :"#{name}?") do
              !!send(name)
            end
          end
        end

        include(mixin)

        attributes[name] = options
      end

      # Define the main record of this form (optional).
      #   Record may be called with form_instance.record
      #
      # @param name
      #   The Symbol attribute name.
      # @option options [Class]
      #   The Class of the type of this attribute. Can be any of String, Integer,
      #   Float, Array, Hash or :boolean.
      def record(name, options = {}, &block)
        define_method(:record) do
          send(name)
        end
        attribute(name, options.merge(:skip => true, :record => true), &block)
      end

      # Retrieve the list of attributes of the form.
      #
      # @return [Hash]
      #   The class attributes hash.
      def attributes
        @attributes ||= {}
      end

      # Useful if you want, for example, all type: :string attributes to use
      # strip: true to remove whitespace padding.
      def set_default_attribute_options(attr_type, options)
        default_attribute_options[attr_type] = options
      end

      def default_attribute_options
        @default_attribute_options ||= {}
      end

      def merge_default_attribute_options(options)
        if options[:type]
          default_attribute_options.fetch(options[:type], {}).merge(options)
        else
          options
        end
      end
    end

    # Extend ClassMethods into including class.
    #
    # @param klass [Class]
    def self.included(klass)
      klass.send(:extend, ClassMethods)
    end

    # Initialize a new Gourami::Form form.
    #
    # @param attrs [Hash]
    #   The attributes values to use for the new instance.
    def initialize(attrs = {})
      set_attributes(attrs)
    end

    # Set the attributes belonging to the form.
    # Overrides ALL existing attributes,
    #   including ones not provided in the `attrs` argument.
    #
    # @param attrs [Hash<[String, Symbol], Object>]
    def set_attributes(attrs)
      return unless attrs.kind_of?(Hash)

      attrs = attrs.map { |k, v| [k.to_s, v] }.to_h

      self.class.attributes.each do |name, opts = {}|
        name = name.to_s

        if attrs.key?(name)
          value = attrs[name]
          provided_attributes_names[name] = opts
        end

        if value.nil? && opts[:required] && !opts[:default]
          # TODO: Consider raising this during validate or perform instead.
          raise RequiredAttributeError, "#{name.inspect} is a required attribute of #{self.class.to_s}"
        end

        send(:"_#{name}=", value)
      end
    end

    # Offer descendants the opportunity to modify attribute values as they are set.
    #
    # @param attribute_name [Symbol] name of the attribute
    # @param value [*] the value as it is passed into the setter
    # @param options [Hash] attribute options
    #
    # @return [*]
    def setter_filter(attribute_name, value, options)
      value
    end

    # Get the all attributes with its values of the current form except the attributes labeled with skip.
    #
    # @return [Hash<Symbol, Object>]
    def attributes
      unskipped_attributes = self.class.attributes.reject { |_, opts| opts[:skip] }
      attributes_hash_from_attributes_options(unskipped_attributes)
    end

    # Get the all attributes with its values of the current form.
    #
    # @return [Hash<Symbol, Object>]
    def all_attributes
      attributes_hash_from_attributes_options(self.class.attributes)
    end

    def provided_attributes
      unskipped_attributes = self.class.attributes.reject { |_, opts| opts[:skip] }
      provided_attributes = unskipped_attributes.select { |name, _| attribute_provided?(name) }
      attributes_hash_from_attributes_options(provided_attributes)
    end

    def provided_attributes_names
      @provided_attributes_names ||= {}
    end

    def attribute_provided?(attribute_name)
      provided_attributes_names.key?(attribute_name.to_s)
    end

    # Get the all attributes given a hash of attributes with options.
    #
    # @param attributes_options [Hash<Symbol, Hash>] attributes with options
    #
    # @return [Hash<Symbol, Object>]
    def attributes_hash_from_attributes_options(attributes_options)
      attributes_options.each_with_object({}) do |(name, _), attrs|
        attrs[name] = send(name)
      end
    end

  end
end
