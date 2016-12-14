require_relative "./spec_helper"

describe Gourami::Attributes do
  let(:form_class) do
    Class.new.tap { |c| c.send(:include, Gourami::Attributes) }
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
end
