# frozen_string_literal: true

require 'ztimer/version'
require 'ztimer/slot'
require 'ztimer/sorted_store'
require 'ztimer/watcher'

# Implements a timer which allows to execute a block with a delay, recurrently or asynchronously.
class Ztimer
  @default_instance = nil

  attr_reader :concurrency, :running, :count, :watcher, :queue

  def initialize(concurrency: 20)
    @concurrency  = concurrency
    @watcher      = Ztimer::Watcher.new { |slot| execute(slot) }
    @workers_lock = Mutex.new
    @count_lock   = Mutex.new
    @queue        = Queue.new
    @running      = 0
    @count        = 0
  end

  # Execute the code block asyncrhonously right now
  def async(&callback)
    enqueued_at = utc_microseconds
    slot        = Slot.new(enqueued_at, enqueued_at, -1, &callback)

    incr_counter!
    execute(slot)

    slot
  end

  # Execute the code block after the specified delay
  def after(milliseconds, &callback)
    enqueued_at = utc_microseconds
    expires_at  = enqueued_at + milliseconds * 1000
    slot        = Slot.new(enqueued_at, expires_at, -1, &callback)

    add(slot)

    slot
  end

  # Execute the code block at a specific datetime
  def at(datetime, &callback)
    enqueued_at = datetime.to_f * 1_000_000

    slot = Slot.new(enqueued_at, enqueued_at, -1, &callback)
    add(slot)

    slot
  end

  # Execute the code block every N milliseconds.
  # When :start_at is specified, the first execution will start at specified date/time
  def every(milliseconds, start_at: nil, &callback)
    enqueued_at = start_at ? start_at.to_f * 1_000_000 : utc_microseconds
    expires_at = enqueued_at + milliseconds * 1000
    slot = Slot.new(enqueued_at, expires_at, milliseconds * 1000, &callback)

    add(slot)

    slot
  end

  # Run ztimer every N seconds, starting with the nearest time slot (ex. secondly(5)
  # will run at second 0, 5, 10, 15, etc.)
  def secondly(seconds, offset: 0, &callback)
    start_time = utc_microseconds
    milliseconds = (seconds.to_f * 1000).to_i
    enqueued_at = start_time - (start_time % (milliseconds * 1000)) + offset * 1_000_000
    expires_at = enqueued_at + milliseconds * 1000

    slot = Slot.new(enqueued_at, expires_at, milliseconds * 1000, &callback)
    add(slot)

    slot
  end

  # Run ztimer every N minutes, starting at the nearest time slot (ex. minutely(2) will run at minute 0, 2, 4, 6, etc.)
  def minutely(minutes, offset: 0, &callback)
    secondly(minutes.to_f * 60, offset: offset.to_f * 60, &callback)
  end

  # Run ztimer every N hours, starting at the nearest time slot (ex. hourly(2) will run at hour 0, 2, 4, 6, etc.)
  def hourly(hours, offset: 0, &callback)
    minutely(hours.to_f * 60, offset: offset.to_f * 60, &callback)
  end

  def daily(days, offset: 0, &callback)
    raise ArgumentError, "Days number should be > 0: #{days.inspect}" if days.to_f <= 0

    hourly(days.to_f * 24, offset: offset.to_f * 24, &callback)
  end

  def day_of_week(day, &callback)
    days = %w[sun mon tue thu wen fri sat]
    current_day = Time.now.wday

    index = day.to_i
    if day.is_a?(String)
      # Find day number by day name
      index = days.index { |day_name| day.strip.downcase == day_name }
      raise ArgumentError, "Invalid week day: #{day.inspect}" if index.nil?
    elsif index.negative? || index > 6
      raise ArgumentError, "Invalid week day: #{day.inspect}"
    end

    offset = 0
    offset = (current_day > index ? index - current_day : current_day - index) if current_day != index

    daily(7, offset: offset, &callback)
  end

  def days_of_week(*args, &callback)
    args.map { |day| day_of_week(day, &callback) }
  end

  def jobs_count
    @watcher.jobs
  end

  def concurrency=(new_value)
    value_is_integer = new_value.is_a?(Integer)
    raise ArgumentError, "Invalid concurrency value: #{new_value}" unless value_is_integer && new_value >= 1

    @concurrency = new_value
  end

  def stats
    {
      running: @running,
      scheduled: @watcher.jobs,
      executing: @queue.size,
      total: @count
    }
  end

  def self.method_missing(name, *args, &block)
    @default_instance ||= Ztimer.new(concurrency: 20)
    @default_instance.send(name, *args, &block)
  end

  protected

  def add(slot)
    incr_counter!
    @watcher << slot
  end

  def incr_counter!
    @count_lock.synchronize{ @count += 1 }
  end

  def execute(slot)
    @queue << slot

    @workers_lock.synchronize do
      [@concurrency - @running, @queue.size].min.times do
        @running += 1
        start_new_thread!
      end
    end
  end

  def start_new_thread!
    worker = Thread.new do
      begin
        loop do
          current_slot = nil
          @workers_lock.synchronize do
            current_slot = @queue.pop(true) unless @queue.empty?
          end
          break if current_slot.nil?

          begin
            current_slot.executed_at = utc_microseconds
            current_slot.callback.call(current_slot) unless current_slot.callback.nil? || current_slot.canceled?
          rescue StandardError => e
            backtrace = e.backtrace ? "\n#{e.backtrace.join("\n")}" : ''
            warn e.inspect + backtrace
          end
        end
      rescue ThreadError
        puts 'queue is empty'
      end
      @workers_lock.synchronize { @running -= 1 }
    end
    worker.abort_on_exception = true
  end

  def utc_microseconds
    Time.now.to_f * 1_000_000
  end
end
