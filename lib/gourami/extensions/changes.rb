module Gourami
  module Extensions
    module Changes

      WATCH_CHANGES_VALID_RETURN_VALUES = [true, false].freeze

      module ClassMethods

        def attribute(name, options = {}, &default_block)
          super.tap do

            mixin = Module.new do |mixin|
              watch_changes = options.fetch(:watch_changes, false)
              if watch_changes
                mixin.send(:define_method, :"_#{name}=") do |value|
                  super(value).tap do |new_value|
                    did_change = if watch_changes.respond_to?(:call)
                      instance_exec(value, &watch_changes)
                    elsif !defined?(record)
                      raise ConfigurationError, "Default `watch_changes` behavior not available without a `record`. Try `attribute(:#{name}, :watch_changes => ->(new_value) { new_value != custom_check_logic )`"
                    elsif record.nil?
                      !new_value.nil?
                    else
                      record.send(name) != new_value
                    end

                    raise WatchChangesError, "`watch_changes` block for `#{name.inspect}` must return one of #{WATCH_CHANGES_VALID_RETURN_VALUES.inspect}." unless WATCH_CHANGES_VALID_RETURN_VALUES.include?(did_change)

                    changed_attributes[name] = did_change
                  end
                end
                mixin.send(:private, :"_#{name}=")
              end
            end

            include(mixin)
          end
        end
      end

      def self.included(klass)
        klass.send(:extend, ClassMethods)
      end

      def changes?(attribute_name)
        options = self.class.attributes.fetch(attribute_name, {})
        watch_changes = options.fetch(:watch_changes, false)

        raise NotWatchingChangesError, "`#{attribute_name}` is not being watched for changes. Try `attribute(:#{attribute_name}, :watch_changes => true)`" unless watch_changes

        changed_attributes.fetch(attribute_name, false)
      end

      private

      def changed_attributes
        @changed_attributes ||= {}
      end

    end
  end
end
