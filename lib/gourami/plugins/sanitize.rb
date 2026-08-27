# Optional plugin adding a :sanitized_string attribute type that strips dangerous HTML
# using loofah. Not loaded by default - opt in with `plugin :sanitize`, and add
# "loofah" to your own application's Gemfile/gemspec.
#
# @example
#   class MyForm < Gourami::Form
#     plugin :sanitize
#
#     attribute :bio, :type => :sanitized_string
#   end
module Gourami
  module Plugins
    module Sanitize
      # Runs on every `plugin :sanitize` call; require is idempotent so this is safe to repeat.
      def self.apply(_model, *)
        require "loofah"
      end

      module InstanceMethods
        # @param value [Object]
        # @param options [Hash] forwarded to #coerce_string
        # @return [String, nil]
        def coerce_sanitized_string(value, options = {})
          value = coerce_string(value, options)
          return value if value.nil?

          # Unescape first so entity-encoded tags (e.g. "&lt;script&gt;") are
          # recognized as real HTML by Loofah instead of passing through as text.
          unescaped_content = CGI.unescapeHTML(value)
          sanitized_content = Loofah.html4_fragment(unescaped_content).scrub!(:prune).to_s
          # Unescape again since loofah would turn a & back into &amp;
          CGI.unescapeHTML(sanitized_content)
        end
      end
    end
  end
end
