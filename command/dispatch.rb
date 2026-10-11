# frozen_string_literal: true

module Terminauta
  module Command
    # Subcommand dispatch, included by BaseCommand. When parsing stopped on
    # a bare token naming a registered subcommand, #call hands the remaining
    # ARGV to that subcommand's execute, passing itself as the parent command
    # (kept in the subcommand's +@parent_command+), and propagates its exit
    # status. Commands can restrict dispatch through #validate_subcommand.
    module Dispatch
      # Entry point: prints help when requested, delegates to a registered
      # subcommand, otherwise checks the declared arguments and runs the
      # command.
      def call
        return puts(help) if @options['help']

        return dispatch if @subcommand_argv

        validate_arguments!
        # spinel miscompiles a bare `run` here: it infers #run's return
        # type as Integer from the subclasses returning one and boxes a
        # nil result as an Integer-tagged sentinel, which then passes
        # .execute's is_a?(Integer) check and leaks out as nil instead
        # of 0. The nil? round trip treats nils as error returns
        result = run
        result.nil? ? 1 : result
      end

      # Hook for commands that restrict what they dispatch to
      # (ColoredCommand overrides it to reject subcommands without color
      # support): receives the subcommand's name and class, raises on an
      # unacceptable combination.
      def validate_subcommand(_name, _subcommand_class)
        nil
      end

      private

      # Raises MissingArgumentError naming the placeholders of all declared
      # arguments without a value, before #run is reached. Declared
      # arguments are required by definition.
      def validate_arguments!
        missing = []
        self.class.arguments.each_with_index do |argument, index|
          missing << argument.value_name if args[index].nil?
        end
        raise MissingArgumentError, "missing #{missing.join(' ')}" unless missing.empty?
      end

      def dispatch
        name = @subcommand_argv[0]
        subcommand_class = self.class.subcommand_for(name)
        validate_subcommand(name, subcommand_class)
        subcommand_class.execute(@subcommand_argv.drop(1), self)
      end
    end
  end
end
