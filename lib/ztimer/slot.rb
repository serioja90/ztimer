# frozen_string_literal: true

class Ztimer
  # Implements a slot, which represents a block of code to be executed at specified time slot.
  class Slot
    attr_reader :enqueued_at, :expires_at, :recurrency, :callback
    attr_accessor :started_at, :executed_at

    def initialize(enqueued_at, expires_at, recurrency = -1, &callback)
      @enqueued_at = enqueued_at
      @expires_at  = expires_at
      @recurrency  = recurrency
      @callback    = callback
      @started_at  = nil
      @executed_at = nil
      @canceled    = false
    end

    def recurrent?
      @recurrency.positive?
    end

    def reset!
      @expires_at += recurrency if recurrent?
    end

    def canceled?
      @canceled
    end

    def cancel!
      @canceled = true
    end

    def <=>(other)
      @expires_at <=> other.expires_at
    end
  end
end
