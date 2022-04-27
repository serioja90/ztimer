# Ztimer

**Ztimer** is a simple Ruby implementation of an asynchronous timer, that allows to enqueue the execution of Ruby
code, so that it will be asynchronously executed on timeout. It's very useful when you need a simple way to execute
some code asynchronously or with a certain delay.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ztimer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ztimer

## Usage

All you have to do is to tell **Ztimer** the delay after which your code have to be executed. An example of how to use it
is illustrated below:

```ruby
require 'ztimer'

delay = 1000 # milliseconds
Ztimer.after(delay) do
  puts "Doing something useful..."
end

# Async execution
Ztimer.async do
  # this code will be executed in background asyncronously
  puts "Doing something useful in background..."
end

# Recurrent jobs
job = Ztimer.every(delay) do # execute the block every second
  puts "Executing a recurrent job..."
end

sleep 10    # wait for 10 seconds (10 executions)
job.cancel! # cancel the recurrent job

# Custom Ztimer instance
my_timer = Ztimer.new(concurrency: 5) # create a new Ztimer instance
10.times do
  # Use the custom ztimer to execute jobs asynchronously
  my_timer.async do
    puts "Doing async job..."
  end
end
```

| Method | Description  |
|--------|-------------|
| `async(&block)` | Execute the block asynchronously. |
| `after(milliseconds, &block)` | Execute the block after the specified amount of milliseconds. |
| `at(datetime, &block)` | Execute the block at the specified timestamp. |
| `every(milliseconds, start_at: nil, &block)` | Execute the block at the specified interval of milliseconds. A custom `:start_at` param could be provided to specify an offset timestamp. |
| `secondly(seconds, offset: 0, &block)` | Executes the block every N seconds. An `:offset` of seconds could be specified to shift the begining of the time slot. By default the block will be exected at the begining of the time slot. Example: `secondly(5)` will run at second `0`, `5`, `10`, `15`, etc. |
| `minutely(minutes, offset: 0, &block)` | Executes the block every N minutes. An `:offset` of minutes could be specified to shift the begining of the time slot. By default the block will be exected at the begining of the time slot. Example: `minutely(5)` will run at minute `0`, `5`, `10`, `15`, etc. |
| `hourly(hours, offset: 0, &block)` | Executes the block every N hours. An `:offset` of hours could be specified to shift the begining of the time slot. By default the block will be exected at the begining of the time slot. Example: `hourly(5)` will run at hour `0`, `5`, `10`, `15`, etc. |
| `daily(days, offset: 0, &block)` | Executes the block every N days. An `:offset` of days could be specified to shift the begining of the time slot. By default the block will be exected at the begining of the time slot. Example: `daily(5)` will run on day `0`, `5`, `10`, `15`, etc. |
| `day_of_week(day, &block)` | Execute the block only on the specified day of week. Valid days are: `"sun", "mon", "tue", "thu", "wen", "fri", "sat"`. |
| `days_of_week(days, &block)` | Execute the block on the specified days of week. |


By default **Ztimer** will run at maximum 20 jobs concurrently, so that if you have 100 jobs to be
executed at the same time, at most 20 of them will run concurrently. This is necessary in order to prevent uncontrolled threads spawn when many jobs have to be run at the same time.

Anyway, you can change the concurrency level by calling `Ztimer.concurrency = <concurrency>`, where `<concurrency>` is the maximum number of `Ztimer` workers allowed to run in parallel (ex: `Ztimer.concurrency = 50`).

If you're using custom **Ztimer** instance, you can specify the concurrency while creating the new instance:

```ruby
my_timer = Ztimer.new(concurrency: 42) # create a ztimer with concurrency set to 42
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serioja90/ztimer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
