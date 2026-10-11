# frozen_string_literal: true

module Terminauta
  module Command
    # A declared command line argument:
    #
    #   Argument.new(:name, description: '...', validator: NameValidator)
    #
    # +name+ is the key of the parsed arguments hash and doubles as
    # the placeholder shown in help and error messages, upcased
    # (:name -> 'NAME'). Declared arguments are required by
    # definition: each one is matched against +args+ in declaration
    # order before #run. +validator+ is an optional
    # Validators::BaseValidator subclass instantiated with the parsed
    # value through #build_validator.
    class Argument
      attr_reader :name, :description, :validator

      def initialize(name, description: nil, validator: nil)
        @name = name.to_s
        @description = description
        @validator = validator
      end

      # Instantiates the declared validator class with +value+.
      # Returns nil when no validator is declared.
      def build_validator(value)
        return nil if @validator.nil?

        @validator.new(value)
      end

      # Placeholder shown in help listings and error messages.
      def value_name
        @name.upcase
      end

      # Key used in the parsed arguments hash.
      def key
        @name
      end
    end
  end
end
