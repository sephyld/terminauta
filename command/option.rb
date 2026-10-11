# frozen_string_literal: true

module Terminauta
  module Command
    # A declared command line option:
    #
    #   Option.new(:name, short: '-n', value: 'NAME', description: '...')
    #   Option.new(:verbose, description: 'Print extra output')
    #
    # +name+ is the key of the parsed options hash ('name'). +long+
    # defaults to '--<name>' and can be overridden. A non-nil +value+
    # makes the option take an argument (the placeholder shown in help,
    # e.g. 'NAME'); nil makes it a boolean flag. +validator+ is an
    # optional Validators::BaseValidator subclass instantiated with
    # the parsed value through #build_validator.
    class Option
      attr_reader :name, :short, :long, :value_name, :description, :validator

      def initialize(name, short: nil, long: nil, value: nil, description: nil, validator: nil)
        @name = name.to_s
        @short = short
        @long = long || "--#{@name}"
        @value_name = value
        @description = description
        @validator = validator
      end

      # Instantiates the declared validator class with +value+.
      # Returns nil when no validator is declared.
      def build_validator(value)
        return nil if @validator.nil?

        @validator.new(value)
      end

      def boolean?
        value_name.nil?
      end

      # Key used in the parsed options hash.
      def key
        @name
      end

      # Left column of the help listing, e.g. '-n, --name NAME'.
      def label
        text = [short, long].compact.join(', ')
        text += " #{value_name}" if value_name
        text
      end
    end
  end
end
