# frozen_string_literal: true

module Terminauta
  module Command
    class Error < StandardError; end

    # Raised when ARGV cannot be matched against the declared options.
    class OptionError < Error; end

    # Raised when a declared argument has no value in +args+. Declared
    # arguments are required by definition. Subclasses OptionError so
    # .execute reports it with the --help hint.
    class MissingArgumentError < OptionError; end
  end
end
