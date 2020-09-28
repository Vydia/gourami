require_relative "./spec_helper"

describe Gourami::Attributes do
  let(:form_class) do
    Class.new do |klass|
      klass.include(Gourami::Attributes)
    end
  end

  describe ".set_default_attribute_options" do
    it "merges attributes options into default_attribute_options upon attribute definition" do
      form_class.set_default_attribute_options(:string, :some_default_option => :foo, :another_option => :foo)
      form_class.attribute(:provide_me, :type => :string, :another_option => :bar)
      options_with_defaults = form_class.merge_default_attribute_options(form_class.attributes.fetch(:provide_me))

      assert_equal(:foo, options_with_defaults.fetch(:some_default_option), "the default should be used when no option provided upon attribute definition")
      assert_equal(:bar, options_with_defaults.fetch(:another_option), "the default should not take precedence when another value is provided upon attribute definition")
    end

    describe "inheritance" do
      let(:form_subclass) do
        form_class.set_default_attribute_options(:string, :some_default_option => :foo, :another_option => :foo)
        Class.new(form_class)
      end

      it "subclasses retain default_attribute_options" do
        form_subclass.attribute(:provide_me, :type => :string, :another_option => :bar)
        options_with_defaults = form_subclass.merge_default_attribute_options(form_subclass.attributes.fetch(:provide_me))

        assert_equal(:foo, options_with_defaults.fetch(:some_default_option), "the default should be used when no option provided upon attribute definition")
        assert_equal(:bar, options_with_defaults.fetch(:another_option), "the default should not take precedence when another value is provided upon attribute definition")
      end
    end

    describe "subtypes like element_type, key_type, and value_type all receive the default_attribute_options too" do
      before do
        form_class.include(Gourami::Coercer)
        form_class.set_default_attribute_options(:string, :upcase => :true)
      end

      it "string coercer receives the options" do
        form_class.attribute(:my_string, :type => :string)
        form = form_class.new(:my_string => "foo")
        assert_equal("FOO", form.my_string)
      end

      it "array element coercer receives the options" do
        form_class.attribute(:my_array, :type => :array, :element_type => :string)
        form = form_class.new(:my_array => ["bar"])
        assert_equal(["BAR"], form.my_array)
      end

      it "hash value coercer receives the options" do
        form_class.attribute(:my_hash, :type => :hash, :value_type => :string)
        form = form_class.new(:my_hash => { "foo" => "bar" })
        assert_equal({ "foo" => "BAR" }, form.my_hash)
      end
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
          klass.include(Gourami::Attributes)
          klass.include(Module.new do
            # Have to `include` a mixin to define the existing method because of weird Ruby quirk with class block syntax and method inheritance chain https://www.ruby-forum.com/t/module-to-overwrite-method-defined-via-define-method/175422/3
            def existing_method_name
              "original method return value"
            end
          end)
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

      describe "when the method is defined from a Gourami attribute" do

        let(:form_class) do
          Class.new do |klass|
            klass.include(Gourami::Attributes)
            klass.include(Module.new do |mod|
              def self.included(base)
                super
                base.attribute(:existing_attribute_name, :default => "original attribute default value")
                base.attribute(:existing_skip_attribute_name, :default => "skip option has no impact", :skip => true)
                base.attribute(:other_attribute_name, :default => "other attribute remains in class.attributes")
              end
            end)
          end
        end

        it "overrides the previously defined attribute without problem" do
          # Before attribute redefine uses previous attribute options
          form = form_class.new
          assert_equal("original attribute default value", form.existing_attribute_name)
          assert_equal("skip option has no impact", form.existing_skip_attribute_name)
          assert_equal("other attribute remains in class.attributes", form.other_attribute_name)

          assert_equal({
            :existing_attribute_name => { :default => "original attribute default value" },
            :existing_skip_attribute_name => { :default => "skip option has no impact", :skip => true },
            :other_attribute_name => { :default => "other attribute remains in class.attributes" },
          }, form_class.attributes)

          # Redefine attributes without problem
          form_class.attribute(:existing_attribute_name, :default => "new default")
          form_class.attribute(:existing_skip_attribute_name)
          form_class.attribute(:new_attribute_name, :skip => true)

          assert_equal({
            :existing_attribute_name => { :default => "new default" },
            :existing_skip_attribute_name => {},
            :other_attribute_name => { :default => "other attribute remains in class.attributes" },
            :new_attribute_name => { :skip => true },
          }, form_class.attributes)

          # After attribute redefine uses new attribute options
          form = form_class.new
          assert_equal("new default", form.existing_attribute_name)
          assert_nil(form.existing_skip_attribute_name)
          assert_equal("other attribute remains in class.attributes", form.other_attribute_name)
          assert_nil(form.new_attribute_name)
        end

      end
    end
  end
end
