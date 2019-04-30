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
