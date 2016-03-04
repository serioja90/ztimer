require 'set'
require 'hitimes'
require 'thread_safe'
require "ztimer/version"
require "ztimer/sorted_store"
require "ztimer/slot"

module Ztimer
  @concurrency  = 20
  @slots        = Ztimer::SortedStore.new
  @metric       = Hitimes::Metric.new("Notifier")
  @monitor      = nil
  @running      = 0
  @workers_lock = Mutex.new
  @io_lock      = Mutex.new
  @queue        = Queue.new

  class << self
    attr_reader :concurrency, :running

    def after(milliseconds, &callback)
      enqueued_at = @metric.utc_microseconds
      expires_at  = enqueued_at + milliseconds * 1000
      slot        = Slot.new(enqueued_at, expires_at, &callback)

      add(slot)

      return slot
    end

    def jobs_count
      return @slots.count
    end

    def concurrency=(new_value)
      raise ArgumentError.new("Invalid concurrency value: #{new_value}") unless new_value.is_a?(Fixnum) && new_value > 1
      @concurrency = new_value
    end

    protected

    def add(slot)
      @io_lock.synchronize do
        @slots << slot
        restart_monitor if @slots.first == slot || @monitor.nil? || !@monitor.alive?
      end
    end

    def restart_monitor
      if @monitor && @monitor.status == "sleep"
        @monitor.kill
      else
        return if @monitor
      end

      @monitor = Thread.new do
        loop do
          delay = @io_lock.synchronize { @slots.empty? ? nil : @slots.first.expires_at - @metric.utc_microseconds }
          break if delay.nil?

          select(nil, nil, nil, delay / 1_000_000.to_f) if delay > 1 # 1 microsecond of cranularity

          @io_lock.synchronize do
            while slot = get_first_expired do
              slot.started_at = @metric.utc_microseconds
              execute(slot)
            end
          end
        end
      end
      @monitor.abort_on_exception = true
    end

    def get_first_expired
      slot = @slots.first
      if slot && (slot.expires_at < @metric.utc_microseconds)
        @slots.shift
      end

      return slot
    end

    def execute(slot)
      @queue.push slot

      @workers_lock.synchronize do
        [@concurrency - @running, @queue.size].min.times do
          @running += 1
          worker = Thread.new do
            begin
              while !@queue.empty? && (slot = @queue.pop(true))
                slot.executed_at = @metric.utc_microseconds
                slot.callback.call(slot) unless slot.callback.nil?
              end
            rescue => e
              STDERR.puts e.inspect + (e.backtrace ? "\n" + e.backtrace.join("\n") : "")
            end
            @workers_lock.synchronize { @running -= 1 }
          end
          worker.abort_on_exception = true
        end
      end
    end
  end
end