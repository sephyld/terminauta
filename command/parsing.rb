# frozen_string_literal: true

require 'optparse'

module Terminauta
  module Command
    # ARGV parsing, included by BaseCommand. Token parsing is delegated to
    # OptionParser, the option parser in the standard library, fed with
    # the options declared through the class level DSL. Supported forms:
    # '--opt value', '--opt=value', '-o value', '-o=value' (normalized to
    # '-o value' first: the spinel OptionParser subset does not strip an
    # inline '=' on short flags), attached short values ('-ovalue'),
    # clustered short flags ('-abc', an attached value belongs to the
    # last flag), boolean flags, the '--' separator and the built-in
    # '-h/--help' flag, which stops parsing: following words are neither
    # parsed nor reported. Parsing also stops at the first bare token
    # naming a registered subcommand: from that token onward, ARGV is
    # left untouched in +@subcommand_argv+ for dispatch, so each level
    # only parses its own options.
    # Declared validators run on parsed values as they are assigned: the
    # first invalid one aborts parsing with ValidationError. Values
    # that materialize later (defaults, prompts) are the command's to
    # validate.
    # NOTE: save option and argument keys both as string and as symbol
    # to accomodate each preference
    module Parsing
      # Raised by the built-in '-h/--help' switch to stop parsing at the
      # flag, as the hand rolled parser always did.
      class HelpRequested < Error; end

      # Hook for commands with extra built-in switches (Ui overrides it
      # for ColoredCommand's --color/--no-color): registers them on
      # +parser+, after the declared options, so an option the command
      # declares on the same flag shadows the built-in switch.
      def register_builtin_switches(_parser)
        nil
      end

      private

      def parse_argv
        parse_tokens
        assign_arguments
      end

      def parse_tokens
        parser = build_parser
        split = subcommand_split_index
        argv = split ? @argv[0, split] : @argv
        argv = normalize_short_values(argv)
        @subcommand_argv = @argv.drop(split) if split
        parser.parse!(argv)
        @args.concat(argv)
      rescue HelpRequested
        nil
      rescue OptionParser::ParseError => e
        raise OptionError, parse_error_message(e)
      end

      # Builds the OptionParser for this command: the built-in -h/--help
      # switch first (it shadows a declared option on the same flags, as
      # before), then the declared options in declaration order, then the
      # built-in switches hook (a declared option on the same flag
      # shadows a built-in one). Raises OptionError when an option is
      # declared on a flag already used by a previous declaration.
      def build_parser
        parser = OptionParser.new
        # Under MRI, OptionParser completes unknown short flags against
        # long flags ('-v' reaches the officious '--version') and
        # abbreviates long ones ('--verb' matches '--verbose'); the
        # spinel OptionParser subset does neither. Exact matching keeps
        # the two in line. respond_to? gates the MRI-only accessor,
        # which the spinel subset does not have.
        parser.require_exact = true if parser.respond_to?(:require_exact=)
        parser.on('-h', '--help') do
          @options['help'] = true
          @options[:help] = true
          raise HelpRequested
        end
        seen_flags = []
        self.class.options.each do |option|
          [option.short, option.long].compact.each do |flag|
            raise OptionError, "option \"#{flag}\" is declared more than once" if seen_flags.include?(flag)

            seen_flags << flag
          end
          register_option(parser, option)
        end
        register_builtin_switches(parser)
        parser
      end

      # Declares +option+ on +parser+ with its short and long flag and
      # its value placeholder ('-n NAME' / '--name NAME'): one switch
      # takes a value when the option does, otherwise both flags are
      # boolean.
      def register_option(parser, option)
        flags = [option.short, option.long].compact
        flags = flags.map { |flag| option.value_name ? "#{flag} #{option.value_name}" : flag }
        flags << option.description if option.description
        parser.on(*flags) { |value| assign_option_value(option, value) }
      end

      # Assigns the value OptionParser parsed for +option+ to the options
      # hash (string and symbol keys), running the declared validator on
      # it. Boolean flags are assigned true.
      def assign_option_value(option, value)
        if option.boolean?
          @options[option.key] = true
          @options[option.key.to_sym] = true
        else
          @options[option.key] = value
          @options[option.key.to_sym] = value
          validate_value!(option, value)
        end
      end

      # Splits the short words with an inline value in two: OptionParser
      # reads an attached short value ('-ovalue') but not an inline '='
      # one ('-o=value' would parse as the attached value '=value'), so
      # '-o=value' is rewritten as '-o' plus 'value', as it has always
      # been accepted. Words from a '--' on are left untouched.
      def normalize_short_values(argv)
        normalized = []
        index = 0
        while index < argv.length
          token = argv[index]
          if token == '--'
            normalized.concat(argv[index..])
            return normalized
          end

          flag, separator, inline = token.partition('=')
          if !separator.empty? && short_value_flag?(flag)
            normalized.push(flag, inline)
          else
            normalized.push(token)
          end
          index += 1
        end
        normalized
      end

      # Whether the last flag of a short word takes a value: an inline
      # '=value' belongs to the last flag of a cluster ('-ab=x' carries
      # the value of '-b'). False for long words, which OptionParser
      # reads inline ('--opt=value') by itself.
      def short_value_flag?(flag)
        return false unless flag.length >= 2 && flag.start_with?('-') && flag[1] != '-'

        option = option_for("-#{flag[-1]}")
        !option.nil? && !option.boolean?
      end

      # Index in +@argv+ of the first bare token naming a registered
      # subcommand, nil when there is none. OptionParser has no notion
      # of subcommands, so the split point is found here: the scan walks
      # +@argv+ skipping the words OptionParser consumes (a non-boolean
      # option word consumes the next word as its value, words with an
      # inline value consume nothing, everything from a '--' on is
      # positional) and stops at the first bare subcommand token.
      def subcommand_split_index
        index = 0
        while index < @argv.length
          token = @argv[index]
          return nil if token == '--'
          return index if self.class.subcommands.key?(token)

          index += 1
          index += 1 if consumes_next_word?(token)
        end
        nil
      end

      # Whether the option word +token+ consumes the next word as its
      # value, mirroring what OptionParser consumes: '--opt value' when
      # the declared option is not boolean, and a short cluster ending
      # in a value-taking flag. Unknown flags consume nothing here:
      # OptionParser reports them in argv order anyway.
      def consumes_next_word?(token)
        return false unless token.start_with?('-') && token != '-'
        return false if token.include?('=')

        if token.start_with?('--')
          option = option_for(token)
          return !option.nil? && !option.boolean?
        end

        letters = token.delete_prefix('-').chars
        letters.each_with_index do |letter, position|
          option = option_for("-#{letter}")
          return false if option.nil?

          next if option.boolean?

          # Value-taking flag: attached to the word, except when it is
          # the last flag of the cluster, which takes the next word.
          return false if position < letters.length - 1

          return true
        end
        false
      end

      # The declared Option matching +flag+ ('--name' or '-n'), nil when
      # none does (the built-in help and color flags, unknown options).
      def option_for(flag)
        self.class.options.find { |option| option.long == flag || option.short == flag }
      end

      # Fills +@arguments+ from the parsed positional args: each declared
      # argument takes the value at its declaration index, when present.
      # Keys are saved both as string and as symbol, like the options.
      def assign_arguments
        self.class.arguments.each_with_index do |argument, index|
          value = @args[index]
          next if value.nil?

          @arguments[argument.key] = value
          @arguments[argument.key.to_sym] = value
          validate_value!(argument, value)
        end
      end

      # Runs the validator declared by +declaration+ (an Argument or an
      # Option) against +value+. No-op when no validator is declared.
      def validate_value!(declaration, value)
        validator = declaration.build_validator(value)
        return if validator.nil?

        validator.validate!
      end

      # Translates an OptionParser error into the OptionError message
      # the framework has always reported: 'unknown option "--bad"',
      # 'option "--url" requires a value (URL)' and the needless
      # argument one.
      def parse_error_message(error)
        message = error.message.partition(': ').last
        case error
        when OptionParser::MissingArgument
          option = option_for(message)
          value_name = option&.value_name
          if value_name
            "option \"#{message}\" requires a value (#{value_name})"
          else
            "option \"#{message}\" requires a value"
          end
        when OptionParser::NeedlessArgument
          needless_argument_message(message.partition('=').first)
        else
          # A short cluster names the word from its failing letter on:
          # report just the failing flag ('-abc' -> '-a').
          flag = message.start_with?('--') || message.length <= 2 ? message : message[0, 2]
          "unknown option \"#{flag}\""
        end
      end

      # Message for a boolean flag given an inline value. The built-in
      # -h/--help has always reported a bare '"--help" does not take a
      # value'; Ui overrides this for --color/--no-color.
      def needless_argument_message(flag)
        return "\"#{flag}\" does not take a value" if ['--help', '-h'].include?(flag)

        "option \"#{flag}\" does not take a value"
      end
    end
  end
end
