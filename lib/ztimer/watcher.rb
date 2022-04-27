# frozen_string_literal: true

class Ztimer
  # Implements a watcher which allows to enqueue Ztimer::Slot items, that will be executed
  # as soon as the time of Ztimer::Slot is reached.
  class Watcher
    def initialize(&callback)
      @thread   = nil
      @slots    = Ztimer::SortedStore.new
      @callback = callback
      @lock     = Mutex.new
      @mutex    = Mutex.new
    end

    def <<(slot)
      @mutex.synchronize do
        @slots << slot
        run if @slots.first == slot
      end
    end

    def jobs
      @slots.size
    end

    protected

    def run
      if @thread
        @thread.wakeup
        @thread.run
      else
        start
      end
    end

    def start
      @lock.synchronize do
        return if @thread

        @thread = Thread.new do
          loop do
            begin
              delay = calculate_delay
              if delay.nil?
                Thread.stop
                next
              end

              select(nil, nil, nil, delay / 1_000_000.to_f) if delay > 1 # 1 microsecond of cranularity

              while fetch_first_expired
              end
            rescue StandardError => e
              puts "#{e.inspect}\n#{e.backtrace.join("\n")}"
            end
          end
        end
        @thread.abort_on_exception = true
      end
    end

    def calculate_delay
      @mutex.synchronize { @slots.empty? ? nil : @slots.first.expires_at - utc_microseconds }
    end

    def fetch_first_expired
      @mutex.synchronize do
        slot = @slots.first
        if slot && (slot.expires_at < utc_microseconds)
          @slots.shift
          slot.started_at = utc_microseconds
          unless slot.canceled?
            execute(slot)
            if slot.recurrent?
              slot.reset!
              @slots << slot
            end
          end
        else
          slot = nil
        end

        slot
      end
    end

    def execute(slot)
      @callback.call(slot)
    end

    def utc_microseconds
      Time.now.to_f * 1_000_000
    end
  end
end
