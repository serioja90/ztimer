# Ztimer

**Ztimer** is a Ruby gem that allows to get asynchronous delayed notifications. You can enqueue callbacks to be
called after some amount of time.

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

By default **Ztimer** will run at maximum 20 jobs concurrently, so that if you have 100 jobs to be
executed at the same time, at maximum 20 of them will run at the same time. This is necessary in order to prevent uncontrolled threads spawn when many jobs have to be sent at the same time.

Anyway, you can change the concurrency by calling `Ztimer.concurrency = <concurrency>`, where `<concurrency>` is the maximum number of `Ztimer` workers allowed to run in parallel (ex: `Ztimer.concurrency = 50`).

If you're using custom **Ztimer** instance, you can specify the concurrency while creating the new instance:

```ruby
my_timer = Ztimer.new(concurrency: 42) # create a ztimer with concurrency set to 42
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/serioja90/ztimer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
