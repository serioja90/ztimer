
module Ztimer
  class Slot
    attr_reader :enqueued_at, :expires_at, :callback
    attr_accessor :started_at, :executed_at

    def initialize(enqueued_at, expires_at, &callback)
      @enqueued_at = enqueued_at
      @expires_at  = expires_at
      @callback    = callback
      @started_at  = nil
      @executed_at = nil
    end

    def <=>(other)
      return @expires_at <=> other.expires_at
    end
  end
end