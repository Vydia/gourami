module Gourami
  class ValidationResourceError < Gourami::Error

    def self.stringify_errors(resource_errors)
      [].tap do |array|
        resource_errors.each do |resource_namespace, resource_namespace_errors|
          resource_namespace_errors.each do |resource_uid, resource_uid_errors|
            resource_uid_errors.each do |attribute_name, error|
               array.push("#{resource_namespace}:#{resource_uid}:#{attribute_name}: #{error}")
            end
          end
        end
      end
    end

    # !@attribute [r] resource_errors
    #   @return [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
    attr_reader :resource_errors

    # Initialize the Gourami::ValidationResourceError.
    #
    # @param errors [Hash<Symbol, Hash<Symbol, Hash<Symbol, Array>>>]
    def initialize(resource_errors)
      @resource_errors = resource_errors
      super(message)
    end

    def message
      @message ||= "Validation failed with errors: #{stringify_errors.join("\n")}"
    end

    private

    def stringify_errors
      ValidationResourceError.stringify_errors(resource_errors)
    end

  end
end
