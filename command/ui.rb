# frozen_string_literal: true

module Terminauta
  module Command
    # Terminal color helpers included by ColoredCommand: optionally ANSI
    # colored messages on stdout, the color:/bold: options in #say and
    # #yes? and the built-in --color/--no-color flags.
    #
    # BaseCommand already provides the plain #say and #yes? through Io,
    # which accept the same options and ignore them; this module overrides
    # both to colorize when asked, and adds #colorize and #color_enabled?.
    #
    # Colors are enabled automatically when stdout is a TTY, forced on
    # with the built-in --color flag and forced off with --no-color or a
    # non-empty NO_COLOR environment variable. --color/--no-color take
    # precedence over NO_COLOR and apply to the whole process, so they
    # work at any subcommand level. BaseCommand knows nothing about any
    # of this: the switch registration and help rows hook in through
    # #register_builtin_switches/#builtin_option_lines, overridden here
    # via the ColoredCommand include order.
    module Ui
      ANSI_RESET = "\e[0m"
      ANSI_BOLD = "\e[1m"

      # ANSI color codes by name, usable as `color: :red` in
      # #say/#yes?/#colorize.
      ANSI_COLORS = {
        black: 30, red: 31, green: 32, yellow: 33,
        blue: 34, magenta: 35, cyan: 36, white: 37
      }.freeze

      # Process wide override set by the built-in --color/--no-color
      # flags, held on the State singleton: true, false or nil (no
      # explicit choice).
      def self.color_override
        State.instance.color_override
      end

      def self.color_override=(value)
        State.instance.color_override = value
      end

      # Prints +message+ on stdout, colored when requested and enabled.
      # Overrides Io#say, which accepts the same options and ignores
      # them: this version colorizes the message and hands it to the
      # plain one.
      #
      #   say 'Installed myapp', color: :green, bold: true
      #   say 'plain message'
      def say(message = '', color: nil, bold: false)
        text = message.to_s
        text = colorize(text, color: color, bold: bold) if color || bold
        super(text)
      end

      # Asks a yes/no question on stdout, colored when requested and
      # enabled, and reads the answer from stdin. Overrides Io#yes?,
      # which accepts the same options and ignores them: this version
      # colorizes the question and hands it to the plain one.
      #
      #   exit 1 unless yes? "Remove #{name}?", color: :yellow
      def yes?(question, default: false, color: nil, bold: false)
        text = question.to_s
        text = colorize(text, color: color, bold: bold) if color || bold
        super(text, default: default)
      end

      # Asks a question on stdout, colored when requested and enabled,
      # and reads a free-form answer from stdin. Overrides Io#ask,
      # which accepts the same options and ignores them: this version
      # colorizes the question and hands it to the plain one.
      #
      #   name = ask "Enter your name", color: :green
      #   path = ask "Enter path", default: "/usr/local", color: :blue
      def ask(question, default: '', color: nil, bold: false)
        text = question.to_s
        text = colorize(text, color: color, bold: bold) if color || bold
        super(text, default: default)
      end

      # Returns +text+ wrapped in ANSI codes when colors are enabled,
      # +text+ itself otherwise.
      def colorize(text, color: nil, bold: false)
        return text unless color_enabled?

        code = color ? ANSI_COLORS[color] : nil
        raise ArgumentError, "unknown color: #{color.inspect}" if color && code.nil?

        prefix = ''
        prefix += ANSI_BOLD if bold
        prefix += "\e[#{code}m" if code
        "#{prefix}#{text}#{ANSI_RESET}"
      end

      # Whether colored output is enabled: --color/--no-color first, then
      # NO_COLOR, then TTY detection.
      def color_enabled?
        return true if Ui.color_override == true
        return false if Ui.color_override == false

        no_color = ENV['NO_COLOR']
        return false if no_color && !no_color.empty?

        $stdout.tty?
      end

      # Parsing hook (see Parsing#register_builtin_switches): registers
      # the built-in --color/--no-color switches on +parser+, unless the
      # command declares its own option with the same long flag (which
      # is registered first and so shadows the built-in switch).
      def register_builtin_switches(parser)
        [['--color', true], ['--no-color', false]].each do |flag, enabled|
          next unless self.class.options.find { |option| option.long == flag }.nil?

          parser.on(flag) { Ui.color_override = enabled }
        end
        nil
      end

      # Message for the built-in flags given an inline value (see
      # Parsing#needless_argument_message): reported as a bare
      # '"--color" does not take a value' unless the command declares
      # its own option on the same flag, which reports the general
      # option message.
      def needless_argument_message(flag)
        return super unless ['--color', '--no-color'].include?(flag)
        return super unless self.class.options.find { |option| option.long == flag }.nil?

        "\"#{flag}\" does not take a value"
      end

      # Help hook (see Help#builtin_option_lines): rows for the built-in
      # --color/--no-color flags, skipped when the command declares its
      # own option with the same long flag.
      def builtin_option_lines
        [['--color', 'Force colored output'], ['--no-color', 'Disable colored output']].select do |long, _description|
          self.class.options.find { _1.long == long }.nil?
        end
      end
    end
  end
end
