# Too Active

A tool for understanding if you're using Active Record _too_ actively.

## Profiling

`TooActive` is quite simple: you pass a block to `TooActive.profile` and then inspect the events that occurred
as the block is executed.

```ruby
TooActive.profile do
  MyModel.all.each do |model|
    puts model.relationships.map(&:id)
  end
end

TooActive.profile do
  MyModel.includes(:relationships).each do |model|
    puts model.relationships.map(&:id)
  end
end
```

It does this by subscribing to event using [`ActiveSupport::Notifications`](https://api.rubyonrails.org/classes/ActiveSupport/Notifications.html).

Currently, `TooActive` only supports `sql.active_record` events, which are fired when a SQL query is executed.

## Installation

Install the gem in your `Gemfile` using bundler, or by building it locally.

```ruby
# Gemfile

gem 'too_active', git: 'git@github.com:thelowlypeon/too_active'
```

If you add it to your Gemfile, you'll probably want to do so only in your test or development environments:

```ruby
# Gemfile

group :development, :test do
  gem 'too_active', git: 'git@github.com:thelowlypeon/too_active'
end
```

## Usage

Pass any block into `profile`:

```ruby
events = TooActive.profile(analyze: false) { my_potentially_expensive_block }
puts events.count # => lots!

TooActive.profile { my_potentially_expensive_block } # => prints analysis
```

Note: This currently only analyzes active record queries and their duration. More to come.
