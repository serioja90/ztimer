require "ztimer/version"
require "ztimer/slot"
require "ztimer/sorted_store"
require "ztimer/watcher"

module Ztimer
  @concurrency  = 20
  @watcher      = Ztimer::Watcher.new(){|slot| execute(slot) }
  @workers_lock = Mutex.new
  @queue        = Queue.new
  @running      = 0
  @count        = 0

  class << self
    attr_reader :concurrency, :running, :count

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

    protected

    def add(slot)
      @count += 1
      @watcher << slot
    end


    def execute(slot)
      @queue << slot

      @workers_lock.synchronize do
        [@concurrency - @running, @queue.size].min.times do
          @running += 1
          worker = Thread.new do
            begin
              while !@queue.empty? && (slot = @queue.pop(true)) do
                slot.executed_at = utc_microseconds
                slot.callback.call(slot) unless slot.callback.nil?
              end
            rescue ThreadError
              # queue is empty
              puts "queue is empty"
            rescue => e
              STDERR.puts e.inspect + (e.backtrace ? "\n" + e.backtrace.join("\n") : "")
            end
            @workers_lock.synchronize { @running -= 1 }
          end
          worker.abort_on_exception = true
        end
      end
    end

    def utc_microseconds
      return Time.now.to_f * 1_000_000
    end
  end
end