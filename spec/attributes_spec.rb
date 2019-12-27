require_relative "./spec_helper"

describe Gourami::Attributes do
  let(:form_class) do
    Class.new do |klass|
      klass.include(Gourami::Attributes)
    end
  end

  describe "#provided_attributes" do
    it "returns a hash" do
      assert_kind_of(Hash, form_class.new.provided_attributes)
    end

    it "only includes attributes that were provided" do
      form_class.attribute(:provide_me)
      form_class.attribute(:provide_me_too)

      form = form_class.new(:provide_me => "foo")
      assert_equal({ :provide_me => "foo" }, form.provided_attributes)

      form.provide_me_too = "bar"
      assert_equal({ :provide_me => "foo", :provide_me_too => "bar" }, form.provided_attributes)
    end

    it "does not include skipped attributes" do
      form_class.attribute(:provide_me, :skip => true)
      form_class.attribute(:provide_me_too, :skip => true)

      form = form_class.new(:provide_me => "foo")
      assert_equal({}, form.provided_attributes)

      form.provide_me_too = "bar"
      assert_equal({}, form.provided_attributes)
    end

    it "includes nil values as long as they are provided" do
      form_class.attribute(:provide_me)
      form_class.attribute(:provide_me_too)

      form = form_class.new(:provide_me => nil)
      assert_equal({ :provide_me => nil }, form.provided_attributes)

      form.provide_me_too = nil
      assert_equal({ :provide_me => nil, :provide_me_too => nil }, form.provided_attributes)
    end
  end

  describe ".attribute" do
    describe "when a method with the attribute name already exists" do
      let(:form_class) do
        Class.new do |klass|
          klass.include(Module.new do
            # Have to `include` a mixin to define the existing method because of weird Ruby quirk with class block syntax and method inheritance chain https://www.ruby-forum.com/t/module-to-overwrite-method-defined-via-define-method/175422/3
            def existing_method_name
              "original method return value"
            end
          end)
          klass.include(Gourami::Attributes)
        end
      end

      it "raises an exception by default" do
        assert_raises Gourami::AttributeNameConflictError do
          form_class.attribute(:existing_method_name)
        end
      end

      it "supports opt-out with :skip_reader => true option" do
        form_class.attribute(:existing_method_name, :skip_reader => true)
        form = form_class.new(:existing_method_name => "attribute value")
        assert_equal("attribute value", form.instance_variable_get(:@existing_method_name))
        assert_equal("original method return value", form.attributes[:existing_method_name])
        assert_equal("original method return value", form.existing_method_name)
      end

      it "supports opt-in with explicit :override_reader => true option" do
        form_class.attribute(:existing_method_name, :override_reader => true)
        form = form_class.new(:existing_method_name => "attribute value")
        assert_equal("attribute value", form.instance_variable_get(:@existing_method_name))
        assert_equal("attribute value", form.attributes[:existing_method_name])
        assert_equal("attribute value", form.existing_method_name)
      end
    end
  end
end
