# frozen_string_literal: true

module Terminauta
  module Command
    module Validators
      # Raised by BaseValidator#validate! when #validate reports errors.
      class ValidationError < Error; end

      # Base class for argument and option validators:
      #
      #   class NameValidator < Terminauta::Command::Validators::BaseValidator
      #     def validate
      #       errors = []
      #       errors << 'Name cannot be empty' if value.nil? || value.empty?
      #       errors
      #     end
      #   end
      #
      # A validator is instantiated with the parsed value (Argument#build_validator
      # / Option#build_validator do it for declared validators). By default
      # declared validators run during parsing, as soon as the value is
      # assigned: the first invalid one aborts the command with
      # ValidationError. Values that materialize after parsing (defaults,
      # prompts) are validated by the command itself through #validate!.
      # Subclasses override #validate and return the list of error
      # messages, empty when the value is valid. #validate! wraps
      # #validate: it raises ValidationError with the collected messages
      # instead of returning them.
      class BaseValidator
        # The parsed value to validate.
        attr_reader :value

        def initialize(value)
          @value = value
        end

        # Returns the Array of error messages collected for +value+,
        # empty when valid. Base implementation reports no errors;
        # subclasses override it.
        def validate
          []
        end

        # Same as #validate, but raises ValidationError with the collected
        # error messages (joined by newlines) when the value is invalid.
        # Returns true otherwise.
        def validate!
          errors = validate
          raise ValidationError, errors.join("\n") unless errors.empty?

          true
        end
      end
    end
  end
end
