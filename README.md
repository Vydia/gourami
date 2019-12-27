# Gourami

Keep your Routes, Controllers and Models thin with Plain Old Ruby Objects (PORO).

## Installation

Add this line to your Gemfile:

```ruby
gem 'gourami'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gourami

## Usage

### A Typical Gourami::Form will

 - Define some attributes
 - Validate user input
 - Perform an action

```ruby
class TypicalForm < Gourami::Form

  attribute(:typical_attribute)

  def validate
    # Define your validation rules here
  end

  def perform
    # Perform your action rules here
  end

end
```

### Your Rails 5 ActionController for the New/Create action:

```ruby
def new
  @form = CreateFishBowl.new
end

def create
  @form = CreateFishBowl.new(fish_bowl_params)

  if @form.valid?
    @form.perform
    redirect_to @form.record
  else
    render "new"
  end
end
```

### Example of a form that Creates a record

```ruby
class CreateFishBowl < Gourami::Form

  record(:fish_bowl)
  attribute(:width, type: :integer)
  attribute(:height, type: :integer)
  attribute(:liters, type: :float)
  attribute(:name, type: :string)
  attribute(:filter_included, type: :boolean, default: false)

  def validate
    validate_presence(:width)
    validate_range(:width, min: 50, max: 1000)

    validate_presence(:height)
    validate_range(:height, min: 50, max: 1000)

    validate_presence(:liters)
    validate_range(:liters, min: 5, max: 200)

    validate_presence(:name)
    validate_uniqueness(:name) do |name|
      FishBowl.where(name: name).empty?
    end
  end

  def perform
    self.fish_bowl = FishBowl.create(attributes)
  end

end
```

### Your Rails 5 ActionController for the Edit/Update action:

```ruby
def edit
  fish_bowl = FishBowl.find(params[:id])
  @form = UpdateFishBowl.new_from_record(fish_bowl)
end

def update
  @form = UpdateFishBowl.new(fish_bowl_params)

  if @form.valid?
    @form.perform
    redirect_to @form.record
  else
    render "edit"
  end
end
```

### Example of a form that Updates a record

```ruby
class UpdateFishBowl < Gourami::Form

  record(:fish_bowl)
  attribute(:width, type: :integer)
  attribute(:height, type: :integer)
  attribute(:liters, type: :float)
  attribute(:name, type: :string)
  attribute(:filter_included, type: :boolean, default: false)

  def self.new_from_record(fish_bowl)
    new(fish_bowl.attributes.merge(fish_bowl: fish_bowl))
  end

  def validate
    validate_presence(:width)
    validate_range(:width, min: 50, max: 1000)

    validate_presence(:height)
    validate_range(:height, min: 50, max: 1000)

    validate_presence(:liters)
    validate_range(:liters, min: 5, max: 200)

    validate_presence(:name)
    validate_uniqueness(:name) do |name|
      FishBowl.where(name: name).empty?
    end
  end

  def perform
    fish_bowl.update(attributes)
  end

end
```

#### Or inherit instead of duplicating the attributes and validations

```ruby
class UpdateFishBowl < CreateFishBowl

  # All attributes and validations inherited from CreateFishBowl.

  def self.new_from_record(fish_bowl)
    new(fish_bowl.attributes.merge(fish_bowl: fish_bowl))
  end

  def perform
    fish_bowl.update(attributes)
  end

end
```

#### Extensions / Plugins

##### Gourami::Extensions::Changes

Check to see if an attribute is being changed:

```ruby
class UpdateUserEmail < Gourami::Form

  include Gourami::Extensions::Changes

  record(:user)
  attribute(:email, :type => :string, :watch_changes => true)

  def perform
    user.update(attributes)

    do_something_like_send_confirmation_email(email) if changes?(:email)
  end

end
```

###### You can implement custom logic to determine if an attribute is changing

This is the equivalent behavior when you set `:watch_changes => true`

```ruby
attribute(:email, :watch_changes => ->(new_value) { new_value != user.email })
```

Your logic to check for changes can be as sophisticated as you want.

```ruby
class UpdatePageAuthorizedUsers < Gourami::Form

  include Gourami::Extensions::Changes

  record(:page)
  attribute(:authorized_users,
    :type => :array,
    :watch_changes => ->(new_value) { new_value.sort.uniq != page.authorized_users.sort.uniq })

  def perform
    page.update(attributes)

    do_something_like_notify_authorization_libraries(authorized_users) if changes?(:authorized_users)
  end

end
```

You can also keep track of side effects due to changes by using `did_change`.

```ruby
class UpdatePageWidgets < Gourami::Form

  include Gourami::Extensions::Changes

  record(:page)
  attribute(:widgets,
    :type => :array,
    :element_type => :string,
    :watch_changes => ->(new_value) {
      did_change(:pro_widget, new_value.include?("pro"))
      new_value.sort.uniq != page.widgets.sort.uniq
    })

  def validate
    append_error(:widgets, :unauthorized) if changes?(:pro_widget) && !current_user_has_pro_account?
  end

end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To add another gem owner to gourami gem `gem owner --add john.smith@example.com gourami`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Vydia/gourami. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
