require "ztimer/version"
require "ztimer/slot"
require "ztimer/sorted_store"
require "ztimer/watcher"

class Ztimer
  @default_instance = nil

  attr_reader :concurrency, :running, :count, :watcher, :queue

  def initialize(concurrency: 20)
    @concurrency  = concurrency
    @watcher      = Ztimer::Watcher.new(){|slot| execute(slot) }
    @workers_lock = Mutex.new
    @count_lock   = Mutex.new
    @queue        = Queue.new
    @running      = 0
    @count        = 0
  end

  def async(&callback)
    enqueued_at = utc_microseconds
    slot        = Slot.new(enqueued_at, enqueued_at, -1, &callback)

    incr_counter!
    execute(slot)

    return slot
  end

  def after(milliseconds, &callback)
    enqueued_at = utc_microseconds
    expires_at  = enqueued_at + milliseconds * 1000
    slot        = Slot.new(enqueued_at, expires_at, -1, &callback)

    add(slot)

    return slot
  end

  def every(milliseconds, &callback)
    enqueued_at = utc_microseconds
    expires_at  = enqueued_at + milliseconds * 1000
    slot        = Slot.new(enqueued_at, expires_at, milliseconds * 1000, &callback)

    add(slot)

    return slot
  end

  def jobs_count
    return @watcher.jobs
  end

  def concurrency=(new_value)
    raise ArgumentError.new("Invalid concurrency value: #{new_value}") unless new_value.is_a?(Fixnum) && new_value >= 1
    @concurrency = new_value
  end


  def stats
    {
      running:   @running,
      scheduled: @watcher.jobs,
      executing: @queue.size,
      total:     @count
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
          rescue => e
            STDERR.puts e.inspect + (e.backtrace ? "\n" + e.backtrace.join("\n") : "")
          end
        end
      rescue ThreadError
        puts "queue is empty"
      end
      @workers_lock.synchronize { @running -= 1 }
    end
    worker.abort_on_exception = true
  end

  def utc_microseconds
    return Time.now.to_f * 1_000_000
  end
end
