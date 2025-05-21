require_relative "../spec_helper"

describe Gourami::Extensions::Resources do
  let(:form_class) do
    Class.new(Gourami::Form).tap do |form|
      form.send(:include, Gourami::Extensions::Resources)
      form.attribute(
        :items,
        description: "List of objects",
        type: :array,
        # element_type does not have to be so precisely defined, but it can be:
        element_type: {
          type: :hash,
          key_type: :string,
          value_type: lambda do |key, value|
            case key
            when *%w[id]
              :integer
            when *%w[name email]
              :string
            when *%w[is_archived]
              :boolean
            when *%w[amount]
              :float
            when *%w[created_at]
              :time
            else
              raise "Unknown key: #{key.inspect}. (value: #{value.inspect})"
            end
          end,
        },
      )
    end
  end

  describe "#append_resource_error and #resource_errors" do
    it "#append_resource_error adds errors to the resource and #resource_errors returns them" do
      form = form_class.new

      assert_equal(false, form.any_resource_errors?)
      assert_equal(false, form.any_errors?)

      assert_equal(false, form.resource_has_errors?(:items, 0))
      assert_equal(false, form.resource_attribute_has_errors?(:items, 0, :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items, 0, :id))

      form.append_resource_error(:items, 0, :name, :is_invalid)

      assert_equal(true, form.any_resource_errors?)
      assert_equal(true, form.any_errors?)

      assert_equal(true, form.resource_has_errors?(:items, 0))
      assert_equal(true, form.resource_attribute_has_errors?(:items, 0, :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items, 0, :id))
    end
  end

  describe "#with_resource" do
    it "validations within the block are scoped to the resource" do
      form = form_class.new(
        items: [
          {
            name: "Sean",
            id: 123,
          },
          {
            name: "Leigh",
            id: 456,
          },
          {
            name: "",
            id: 789,
          },
        ],
      )
      form.items.each_with_index do |item, index|
        form.with_resource(:items, index) do
          form.validate_presence(:name)
          # TODO: support `append_error` on resource.
          # form.append_error(:name, :is_invalid)
        end
      end
      assert_equal(false, form.resource_has_errors?(:items, 0))
      assert_equal(false, form.resource_has_errors?(:items, 1))
      assert_equal(true, form.resource_has_errors?(:items, 2))
      assert_equal(false, form.resource_attribute_has_errors?(:items, 0, :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items, 1, :name))
      assert_equal(true, form.resource_attribute_has_errors?(:items, 2, :name))
    end
  end
end
