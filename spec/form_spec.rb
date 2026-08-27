require_relative "./spec_helper"

describe Gourami::Form do
  describe ".plugin" do
    it "mixes in ClassMethods, InstanceMethods, and calls apply then configure" do
      calls = []

      plugin_module = Module.new do
        define_singleton_method(:apply) { |model, *args| calls << [:apply, model, args] }
        define_singleton_method(:configure) { |model, *args| calls << [:configure, model, args] }

        const_set(:ClassMethods, Module.new { define_method(:hello) { "hi" } })
        const_set(:InstanceMethods, Module.new { define_method(:world) { "earth" } })
      end

      form_class = Class.new(Gourami::Form) do
        plugin(plugin_module, :some_arg)
      end

      assert_equal("hi", form_class.hello)
      assert_equal("earth", form_class.new.world)
      assert_equal([[:apply, form_class, [:some_arg]], [:configure, form_class, [:some_arg]]], calls)
    end

    it "passes the block through to apply and configure" do
      apply_block_result = nil
      configure_block_result = nil

      plugin_module = Module.new do
        define_singleton_method(:apply) { |_model, &block| apply_block_result = block.call }
        define_singleton_method(:configure) { |_model, &block| configure_block_result = block.call }
      end

      Class.new(Gourami::Form) do
        plugin(plugin_module) { "block result" }
      end

      assert_equal("block result", apply_block_result)
      assert_equal("block result", configure_block_result)
    end

    it "resolves a Symbol to Gourami::Plugins::CamelizedName and requires gourami/plugins/name" do
      form_class = Class.new(Gourami::Form) do
        plugin :sanitize

        attribute :bio, :type => :sanitized_string
      end

      form = form_class.new(:bio => "<script>alert(1)</script><p>ok</p>")

      assert_equal("<p>ok</p>", form.bio)
    end
  end
end
