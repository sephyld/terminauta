# frozen_string_literal: true

module Terminauta
  module Command
    # The single process wide terminauta state, reachable through
    # State.instance. A classic singleton: initialize is protected and
    # new is private, so the only instance is the one created lazily
    # by State.instance. (Protecting initialize alone would not block
    # State.new: Class#new invokes initialize through an internal path
    # that ignores its visibility, hence the private new.)
    #
    # The instance is created lazily with `@instance ||= new`: under
    # spinel a class ivar that was never assigned reads as false
    # instead of nil, which the ||= assignment tolerates. initialize
    # pins @color_override to nil explicitly for the same reason: unset
    # (auto detection) must stay distinguishable from --no-color.
    class State
      def initialize
        @color_override = nil
      end

      protected :initialize

      # The single State instance, created on first call.
      def self.instance
        @instance ||= new
      end

      private_class_method :new

      # Process wide override set by the built-in --color/--no-color
      # flags: true, false or nil (no explicit choice).
      attr_accessor :color_override
    end
  end
end
