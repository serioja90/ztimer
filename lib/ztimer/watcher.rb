
module Ztimer
  class Watcher

    def initialize(&callback)
      @thread   = nil
      @idler    = Lounger.new
      @slots    = Ztimer::SortedStore.new
      @callback = callback
      @lock     = Mutex.new
      @metric   = Hitimes::Metric.new("Notifier")
      @mutex    = Mutex.new
    end

    def << (slot)
      @mutex.synchronize do
        @slots << slot
        if @slots.first == slot
          run
        end
      end
    end

    def jobs
      return @slots.size
    end

    protected

    def run
      if @thread
        @idler.signal && @thread.run
      else
        start
      end
    end

    def start
      @lock.synchronize do
        return if @thread
        @thread = Thread.new do
          loop do
            delay = get_delay
            if delay.nil?
              @idler.wait
              next
            end

            select(nil, nil, nil, delay / 1_000_000.to_f) if delay > 1 # 1 microsecond of cranularity

            while get_first_expired do
            end
          end
        end
        @thread.abort_on_exception = true
      end
    end

    def get_delay
      return @mutex.synchronize { @slots.empty? ? nil : @slots.first.expires_at - @metric.utc_microseconds }
    end

    def get_first_expired
      @mutex.synchronize do
        slot = @slots.first
        if slot && (slot.expires_at < @metric.utc_microseconds)
          @slots.shift
          slot.started_at = @metric.utc_microseconds
          execute(slot) unless slot.canceled?
        else
          slot = nil
        end

        slot
      end
    end

    def execute(slot)
      @callback.call(slot)
    end
  end
end