# frozen_string_literal: true

module Terminauta
  module Command
    # Class level DSL for commands. Extended by BaseCommand, so every
    # subclass gets description/usage/command_name/option declarations,
    # the option registry and the execute entry point.
    module ClassMethods
      # Sets/returns the one line description shown in help output.
      def description(text = nil)
        return @description if text.nil?

        @description = text
      end

      # Sets/returns the usage line shown in help output. Defaults to
      # '<command name> [options] [ARGS]'.
      def usage(text = nil)
        return @usage if text.nil?

        @usage = text
      end

      # Sets/returns the command name used in help output. Defaults to the
      # class name, downcased, with a trailing '::Command' namespace part
      # stripped (Todo::Command -> 'todo').
      def command_name(name = nil)
        @command_name = name unless name.nil?
        return @command_name if @command_name

        parts = to_s.split('::')
        parts.pop if parts.length > 1 && parts.last == 'Command'
        parts.map(&:downcase).join(' ')
      end

      # Declares an option. +name+ is the key in the parsed options hash
      # and defaults the long flag to '--<name>'.
      #
      #   option :name, short: '-n', value: 'NAME', description: '...', validator: NameValidator
      #   option :verbose, description: 'Print extra output'
      def option(name, short: nil, long: nil, value: nil, description: nil, validator: nil)
        options << Option.new(name, short: short, long: long, value: value,
                              description: description, validator: validator)
        nil
      end

      # All declared options. Each subclass builds its own list.
      def options
        @options ||= []
      end

      # Declares a positional argument, required by definition:
      # +name+ is the key of the parsed +arguments+ hash and doubles
      # as the placeholder shown in help and error messages, upcased
      # (:name -> 'NAME'). Declared arguments are matched against +args+
      # in declaration order before #run: a missing one raises
      # MissingArgumentError, reported as '<command>: missing NAME'
      # with the --help hint, exit status 1. Positional arguments that
      # are not declared are not checked and stay in +args+. A declared
      # +validator+ runs during parsing on the parsed value: the first
      # invalid one aborts with Validators::ValidationError, exit 1.
      #
      #   argument :name, description: 'Name of the application', validator: NameValidator
      def argument(name, description: nil, validator: nil)
        arguments << Argument.new(name, description: description, validator: validator)
        nil
      end

      # All declared arguments. Each subclass builds its own list.
      def arguments
        @arguments ||= []
      end

      # Registers +klass+ as a subcommand invoked with +name+. When ARGV
      # contains +name+ as the first bare token, parsing stops there and
      # the remaining arguments are delegated to the subcommand.
      def subcommand(name, klass)
        subcommands[name] = klass
        nil
      end

      # All registered subcommands, as { 'name' => class }.
      def subcommands
        @subcommands ||= {}
      end

      # Finds the subcommand class registered under +name+.
      def subcommand_for(name)
        subcommands[name]
      end

      # Builds the command from +argv+, runs it and returns a process exit
      # status. An Integer returned by #run (or by a subcommand's #run) is
      # propagated; anything else means success. Option errors are reported
      # on stderr. +parent_command+ is the command instance dispatching to
      # this one, nil for the root command.
      def execute(argv = ARGV, parent_command = nil)
        command = new(argv, parent_command)
        result = command.call
        result.is_a?(Integer) ? result : 0
      rescue Validators::ValidationError => e
        warn "#{command_name}: #{e.message}"
        1
      rescue OptionError => e
        warn "#{command_name}: #{e.message}"
        warn "Try '#{command_name} --help' for more information."
        1
      end
    end
  end
end
