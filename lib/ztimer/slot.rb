
class Ztimer
  class Slot
    attr_reader :enqueued_at, :expires_at, :recurrency, :callback
    attr_accessor :started_at, :executed_at

    def initialize(enqueued_at, expires_at,recurrency = -1, &callback)
      @enqueued_at = enqueued_at
      @expires_at  = expires_at
      @recurrency  = recurrency
      @callback    = callback
      @started_at  = nil
      @executed_at = nil
      @canceled    = false
    end

    def recurrent?
      return @recurrency > 0
    end

    def reset!
      if recurrent?
        @expires_at += recurrency
      end
    end

    def canceled?
      return @canceled
    end

    def cancel!
      @canceled = true
    end

    def <=>(other)
      return @expires_at <=> other.expires_at
    end
  end
end
