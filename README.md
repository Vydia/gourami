# Gourami

Keep your Routes, Controllers and Models thin.

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

 - list a set of attributes
 - validate user input
 - perform an action

```ruby
class TypicalForm < Gourami::Form

  attribute(:typical_attribute)

  def validate
    # Define Your validation rules here
  end

  def perform
    # Perform your action rules here
  end

end
```

### Your Rails 5 ActionController for the New/Create action:

```ruby
def new
  @form = CreateFishTank.new
end

def create
  @form = CreateFishTank.new(fish_tank_params)

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
class CreateFishTank < Gourami::Form

  record(:fish_tank)

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
      FishTank.where(name: name).empty?
    end
  end

  def perform
    self.fish_tank = FishTank.create(attributes)
  end

end
```

### Your Rails 5 ActionController for the Edit/Update action:

```ruby
def edit
  fish_tank = FishTank.find(params[:id])
  @form = UpdateFishTank.new_from_record(fish_tank)
end

def update
  @form = UpdateFishTank.new(fish_tank_params)

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
class UpdateFishTank < CreateFishTank

  record(:fish_tank)

  attribute(:width, type: :integer)
  attribute(:height, type: :integer)
  attribute(:liters, type: :float)
  attribute(:name, type: :string)
  attribute(:filter_included, type: :boolean, default: false)

  def self.new_from_record(fish_tank)
    new({ fish_tank: fish_tank }.merge(fish_tank.attributes))
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
      FishTank.where(name: name).empty?
    end
  end

  def perform
    fish_tank.update(attributes)
  end

end
```

#### Or inherit instead of duplicating the attributes and validations

```ruby
class UpdateFishTank < CreateFishTank

  # All attributes and validations inherited from CreateFishTank.

  def self.new_from_record(fish_tank)
    new({ fish_tank: fish_tank }.merge(fish_tank.attributes))
  end

  def perform
    fish_tank.update(attributes)
  end

end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TSMMark/gourami. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
