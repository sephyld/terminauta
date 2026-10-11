# frozen_string_literal: true

# Colored output (see command/ui.rb) and the process wide color state
# (see command/state.rb): #colorize, #color_enabled?, the built-in
# --color/--no-color flags and the NO_COLOR environment variable. Run
# under `spin test`, which diffs the spinel compiled output against a
# plain CRuby run of the same file: both must agree.
require_relative '../terminauta'
require_relative 'support/test_utils'

# Runs +command_class+ on +argv+, printing the command's output or the
# reported error. Rescues here, not through .execute, so every message
# lands on stdout where the test diff reads it.
def run(command_class, argv)
  puts "-- #{command_class.command_name} #{argv.join(' ')}"
  command = command_class.new(argv)
  command.call
rescue Terminauta::Command::Error, Terminauta::Command::Validators::ValidationError => e
  puts "error: #{e.message}"
end

# #colorize and the colored #say, with colors forced on and off.
class ColorCommand < Terminauta::Command::ColoredCommand
  command_name 'color'
  option :verbose, short: '-v', description: 'Verbose'

  def run
    puts "override=#{Terminauta::Command::Ui.color_override.inspect} enabled=#{color_enabled?.inspect}"
    puts "plain=#{colorize('text').inspect}"
    puts "red=#{colorize('text', color: :red).inspect}"
    puts "bold=#{colorize('text', bold: true).inspect}"
    puts "red_bold=#{colorize('text', color: :red, bold: true).inspect}"
    begin
      colorize('text', color: :pink)
    rescue ArgumentError => e
      puts "unknown_color=#{e.message.inspect}"
    end
    say 'say plain'
    say 'say red', color: :red
    say 'say bold', bold: true
    0
  end
end

Terminauta::Command::Ui.color_override = nil
run(ColorCommand, ['--color'])
Terminauta::Command::Ui.color_override = nil
run(ColorCommand, ['--no-color'])
Terminauta::Command::Ui.color_override = nil
run(ColorCommand, [])

# NO_COLOR forces colors off; --color/--no-color win over it. The
# override is process wide (State), so it is reset between runs.
class ProbeCommand < Terminauta::Command::ColoredCommand
  command_name 'probe'

  def run
    puts "override=#{Terminauta::Command::Ui.color_override.inspect} " \
         "enabled=#{color_enabled?.inspect} tty=#{$stdout.tty?.inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = nil
run(ProbeCommand, [])
ENV['NO_COLOR'] = '1'
run(ProbeCommand, [])
Terminauta::Command::Ui.color_override = true
run(ProbeCommand, [])
Terminauta::Command::Ui.color_override = false
run(ProbeCommand, [])
Terminauta::Command::Ui.color_override = nil
ENV['NO_COLOR'] = ''
run(ProbeCommand, [])

# A plain BaseCommand knows nothing about colors: --color/--no-color
# are unknown options and #say ignores the color:/bold: options.
class PlainCommand < Terminauta::Command::BaseCommand
  command_name 'plain'

  def run
    say 'plain say', color: :red, bold: true
    0
  end
end

run(PlainCommand, ['--color'])
run(PlainCommand, ['--no-color'])
run(PlainCommand, [])

# The colored #say/#yes?/#ask colorize when colors are enabled. The
# prompts are fed scripted answers (see TestUtils.feed_stdin).
class PromptColorCommand < Terminauta::Command::ColoredCommand
  command_name 'promptcolor'

  def run
    say 'say red', color: :red
    puts "yes=#{yes?('Remove it?', color: :yellow).inspect}"
    puts "ask=#{ask('Enter a name', default: 'x', color: :green).inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = true
TestUtils.feed_stdin("y\nBob\n")
run(PromptColorCommand, [])
Terminauta::Command::Ui.color_override = false
TestUtils.feed_stdin("y\nBob\n")
run(PromptColorCommand, [])
Terminauta::Command::Ui.color_override = nil

# The built-in flags get help rows on a ColoredCommand only.
puts "plain_rows=#{PlainCommand.new([]).builtin_option_lines.inspect}"
puts "colored_rows=#{ColorCommand.new([]).builtin_option_lines.inspect}"
