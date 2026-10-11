# frozen_string_literal: true

module Terminauta
  module Command
    # Help output rendering, included by BaseCommand.
    module Help
      def help
        usage = self.class.usage || "#{self.class.command_name} [options] [ARGS]"
        lines = ["Usage: #{usage}"]
        if self.class.description
          lines << ''
          lines << self.class.description
        end
        lines << ''
        unless self.class.subcommands.empty?
          lines << 'Commands:'
          self.class.subcommands.each do |name, subcommand|
            lines << "  #{name.ljust(22)}#{subcommand.description}"
          end
          lines << ''
        end
        unless self.class.arguments.empty?
          lines << 'Arguments:'
          self.class.arguments.each do |argument|
            lines << "  #{argument.value_name.ljust(22)}#{argument.description}"
          end
          lines << ''
        end
        lines << 'Options:'
        self.class.options.each do |option|
          lines << "  #{option.label.ljust(22)}#{option.description}"
        end
        lines << "  #{'-h, --help'.ljust(22)}Show this help"
        builtin_option_lines.each do |label, description|
          lines << "  #{label.ljust(22)}#{description}"
        end
        lines.map(&:rstrip).join("\n")
      end

      # Hook for commands with extra built-in flags (Ui overrides it for
      # ColoredCommand's --color/--no-color): extra [label, description]
      # rows listed in the Options section.
      def builtin_option_lines
        []
      end
    end
  end
end
