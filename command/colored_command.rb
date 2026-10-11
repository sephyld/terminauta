# frozen_string_literal: true

require_relative 'base_command'
require_relative 'ui'

module Terminauta
  module Command
    # A BaseCommand with colored output, for commands that want it:
    #
    #   class Todo::Command < Terminauta::Command::ColoredCommand
    #     # ...
    #   end
    #
    # Including Ui overrides #say to accept color:/bold: (ANSI colors,
    # enabled on a TTY, forced with --color/--no-color, NO_COLOR honored),
    # adds #colorize/#color_enabled? and the built-in --color/--no-color
    # flags with their help rows. The plain #say and the #yes? prompts
    # come from Io via BaseCommand; inherit BaseCommand instead when a
    # command should not support colors.
    #
    # Color support must be uniform along a dispatch chain, so a
    # --color/--no-color flag parsed by one level is meaningful for all
    # of them: a ColoredCommand raises Terminauta::Command::Error when its
    # parent command or one of its subcommands does not include Ui.
    class ColoredCommand < BaseCommand
      include Ui

      def initialize(argv = [], parent_command = nil)
        super(argv, parent_command)
        return if parent_command.nil? || parent_command.is_a?(Ui)

        raise Error, "#{self.class} supports colored output but its parent command #{parent_command.class} does not"
      end

      # See Dispatch#validate_subcommand: ColoredCommand only dispatches
      # to commands that support colors too. Goes through #ancestors:
      # spinel miscompiles Module#include? on a class only known at
      # runtime (it answers false where MRI answers true).
      def validate_subcommand(name, subcommand_class)
        return if subcommand_class.ancestors.include?(Ui)

        raise Error, "#{self.class} supports colored output but its subcommand #{name} (#{subcommand_class}) does not"
      end
    end
  end
end
