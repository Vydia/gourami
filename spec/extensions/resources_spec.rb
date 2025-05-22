require_relative "../spec_helper"

describe Gourami::Extensions::Resources do
  let(:form_class) do
    Class.new(Gourami::Form).tap do |form|
      form.send(:include, Gourami::Extensions::Resources)
      form.attribute(
        :items,
        description: "Array list of objects",
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
      form.attribute(
        :items_hash,
        description: "Hash list of objects",
        type: :hash,
        key_type: :string,
        value_type: {
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

  describe "#with_resource(:items, index) # Array" do
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
      offset = 3
      form.items.each_with_index do |item, index|
        form.with_resource(:items, index, offset: offset) do
          form.validate_presence(:name)
          form.append_error(:id, :is_invalid) if item["id"] > 500
        end
      end

      assert_equal(false, form.resource_has_errors?(:items, offset + 0))
      assert_equal(false, form.resource_has_errors?(:items, offset + 1))
      assert_equal(true, form.resource_has_errors?(:items, offset + 2))

      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 0, :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 0, :id))
      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 1, :name))

      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 1, :id))
      assert_equal(true, form.resource_attribute_has_errors?(:items, offset + 2, :name))
      assert_equal(true, form.resource_attribute_has_errors?(:items, offset + 2, :id))
    end
  end

  describe "#with_each_resource(:items) do |item, index| # Array" do
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
      offset = 3

      received_items = []
      received_keys = []
      received_indexes = []
      form.with_each_resource(:items, offset: offset) do |item, key, index|
        received_items << item
        received_keys << key
        received_indexes << index

        form.validate_presence(:name)
        form.append_error(:id, :is_invalid) if item["id"] > 500
      end

      assert_equal(
        [
          {
            "name" => "Sean",
            "id" => 123,
          },
          {
            "name" => "Leigh",
            "id" => 456,
          },
          {
            "name" => "",
            "id" => 789,
          },
        ],
        received_items
      )
      assert_equal(
        [
          offset + 0,
          offset + 1,
          offset + 2,
        ],
        received_keys
      )

      assert_equal(
        [
          0,
          1,
          2,
        ],
        received_indexes
      )

      assert_equal(false, form.resource_has_errors?(:items, offset + 0))
      assert_equal(false, form.resource_has_errors?(:items, offset + 1))
      assert_equal(true, form.resource_has_errors?(:items, offset + 2))

      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 0, :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 0, :id))
      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 1, :name))

      assert_equal(false, form.resource_attribute_has_errors?(:items, offset + 1, :id))
      assert_equal(true, form.resource_attribute_has_errors?(:items, offset + 2, :name))
      assert_equal(true, form.resource_attribute_has_errors?(:items, offset + 2, :id))
    end
  end

  describe "#with_resource(:items, index) # Hash" do
    it "validations within the block are scoped to the resource" do
      form = form_class.new(
        items_hash: {
          "abc" => {
            name: "Sean",
            id: 123,
          },
          "def" => {
            name: "Leigh",
            id: 456,
          },
          "ghi" => {
            name: "",
            id: 789,
          },
        },
      )
      form.items_hash.each do |key, item|
        form.with_resource(:items_hash, key) do
          form.validate_presence(:name)
          form.append_error(:id, :is_invalid) if item["id"] > 500
        end
      end

      assert_equal(false, form.resource_has_errors?(:items_hash, "abc"))
      assert_equal(false, form.resource_has_errors?(:items_hash, "def"))
      assert_equal(true, form.resource_has_errors?(:items_hash, "ghi"))

      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "abc", :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "abc", :id))
      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "def", :name))

      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "def", :id))
      assert_equal(true, form.resource_attribute_has_errors?(:items_hash, "ghi", :name))
      assert_equal(true, form.resource_attribute_has_errors?(:items_hash, "ghi", :id))
    end
  end

  describe "#with_each_resource(:items) do |item, index| # Hash" do
    it "validations within the block are scoped to the resource" do
      form = form_class.new(
        items_hash: {
          "abc" => {
            name: "Sean",
            id: 123,
          },
          "def" => {
            name: "Leigh",
            id: 456,
          },
          "ghi" => {
            name: "",
            id: 789,
          },
        }
      )

      received_items = []
      received_keys = []
      received_indexes = []
      form.with_each_resource(:items_hash) do |item, key, index|
        received_items << item
        received_keys << key
        received_indexes << index

        form.validate_presence(:name)
        form.append_error(:id, :is_invalid) if item["id"] > 500
      end

      assert_equal(
        [
          {
            "name" => "Sean",
            "id" => 123,
          },
          {
            "name" => "Leigh",
            "id" => 456,
          },
          {
            "name" => "",
            "id" => 789,
          },
        ],
        received_items
      )
      assert_equal(
        [
          "abc",
          "def",
          "ghi",
        ],
        received_keys
      )

      assert_equal(
        [
          0,
          1,
          2,
        ],
        received_indexes
      )

      assert_equal(false, form.resource_has_errors?(:items_hash, "abc"))
      assert_equal(false, form.resource_has_errors?(:items_hash, "def"))
      assert_equal(true, form.resource_has_errors?(:items_hash, "ghi"))

      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "abc", :name))
      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "abc", :id))
      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "def", :name))

      assert_equal(false, form.resource_attribute_has_errors?(:items_hash, "def", :id))
      assert_equal(true, form.resource_attribute_has_errors?(:items_hash, "ghi", :name))
      assert_equal(true, form.resource_attribute_has_errors?(:items_hash, "ghi", :id))
    end
  end
end
