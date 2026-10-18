# frozen_string_literal: true

# Interactive picker (see command/io.rb and command/ui.rb): #pick
# renders a question and a list of choices, moves the cursor with the
# arrow keys or j/k, selects with enter or space and cancels with
# Ctrl-C, ESC or EOF (returning nil). The keystrokes are fed scripted
# through stdin (see TestUtils.feed_stdin): escape sequences for the
# arrow keys, j/k, enter, space, Ctrl-C and EOF. Run under `spin test`,
# which diffs the spinel compiled output against a plain CRuby run of
# the same file: both must agree.
#
# The two EOF scenarios come last on purpose: under spinel a read that
# hits EOF sticks across $stdin.reopen (the EOF flag is not cleared),
# so no scenario may feed stdin after one that read to EOF.
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

class PickerCommand < Terminauta::Command::ColoredCommand
  command_name 'picker'

  def run
    puts "picked=#{pick('Pick a fruit', ['Apple', 'Banana', 'Cherry']).inspect}"
    0
  end
end

# Arrow keys move the cursor (down, down), enter selects.
TestUtils.feed_stdin("\e[B\e[B\r")
run(PickerCommand, [])

# Vim keys: j j k moves down, down, up; enter selects.
TestUtils.feed_stdin("jjk\r")
run(PickerCommand, [])

# The cursor wraps around: k on the first choice selects the last one.
TestUtils.feed_stdin("k\r")
run(PickerCommand, [])

# Space selects the choice under the cursor.
TestUtils.feed_stdin(' ')
run(PickerCommand, [])

# Ctrl-C cancels: #pick returns nil.
TestUtils.feed_stdin("\x03")
run(PickerCommand, [])

# Keys that are not part of the picker are ignored: x, the right
# arrow and the Home key leave the cursor on the first choice.
TestUtils.feed_stdin("x\e[C\e[H\r")
run(PickerCommand, [])

# #pick returns the chosen value itself, whatever its type.
class ValuePickerCommand < Terminauta::Command::BaseCommand
  command_name 'valuepicker'

  def run
    puts "picked=#{pick('Pick a value', [1, 2, 3]).inspect}"
    0
  end
end

TestUtils.feed_stdin("j\r")
run(ValuePickerCommand, [])

# A Hash maps the returned values (the keys) to the displayed labels
# (the values): the labels are listed, the keys are returned.
class HashPickerCommand < Terminauta::Command::BaseCommand
  command_name 'hashpicker'

  def run
    puts "picked=#{pick('Pick a size', { s: 'Small', l: 'Large' }).inspect}"
    0
  end
end

TestUtils.feed_stdin("j\r")
run(HashPickerCommand, [])

# An empty choice list is rejected.
class EmptyPickerCommand < Terminauta::Command::BaseCommand
  command_name 'emptypicker'

  def run
    pick('Pick nothing', [])
    0
  end
end

begin
  EmptyPickerCommand.new([]).call
rescue ArgumentError => e
  puts "empty=#{e.message.inspect}"
end

# An empty Hash is rejected too.
class EmptyHashPickerCommand < Terminauta::Command::BaseCommand
  command_name 'emptyhashpicker'

  def run
    pick('Pick nothing', {})
    0
  end
end

begin
  EmptyHashPickerCommand.new([]).call
rescue ArgumentError => e
  puts "empty=#{e.message.inspect}"
end

# The colored #pick colorizes the question when colors are enabled
# and leaves the choices plain without format_choices; a plain
# BaseCommand accepts and ignores the color options.
class ColoredPickerCommand < Terminauta::Command::ColoredCommand
  command_name 'coloredpicker'

  def run
    puts "picked=#{pick('Pick a fruit', ['Apple', 'Banana'], color: :green).inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = true
TestUtils.feed_stdin("\r")
run(ColoredPickerCommand, [])
Terminauta::Command::Ui.color_override = false
TestUtils.feed_stdin("\r")
run(ColoredPickerCommand, [])
Terminauta::Command::Ui.color_override = nil

# With format_choices: true the choice labels get the same color/bold
# codes as the question.
class ColoredChoicesPickerCommand < Terminauta::Command::ColoredCommand
  command_name 'coloredchoicespicker'

  def run
    puts "picked=#{pick('Pick a fruit', ['Apple', 'Banana'], color: :green, bold: true, format_choices: true).inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = true
TestUtils.feed_stdin("\r")
run(ColoredChoicesPickerCommand, [])
Terminauta::Command::Ui.color_override = nil

# format_choices also works with a Hash: the labels are colorized, the
# keys are still returned plain.
class ColoredHashPickerCommand < Terminauta::Command::ColoredCommand
  command_name 'coloredhashpicker'

  def run
    puts "picked=#{pick('Pick a size', { s: 'Small', l: 'Large' }, color: :green, format_choices: true).inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = true
TestUtils.feed_stdin("j\r")
run(ColoredHashPickerCommand, [])
Terminauta::Command::Ui.color_override = nil

# format_choices: true without color/bold leaves the choices plain.
class ColorChoicesPlainCommand < Terminauta::Command::ColoredCommand
  command_name 'colorchoicesplain'

  def run
    puts "picked=#{pick('Pick a fruit', ['Apple', 'Banana'], format_choices: true).inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = true
TestUtils.feed_stdin("\r")
run(ColorChoicesPlainCommand, [])
Terminauta::Command::Ui.color_override = nil

class PlainPickerCommand < Terminauta::Command::BaseCommand
  command_name 'plainpicker'

  def run
    puts "picked=#{pick('Pick a fruit', ['Apple', 'Banana'], color: :red, bold: true, format_choices: true).inspect}"
    0
  end
end

TestUtils.feed_stdin("\r")
run(PlainPickerCommand, [])

# ESC cancels too, and so does EOF (no input at all). Both read stdin
# to EOF, so they must stay last (see the header comment).
TestUtils.feed_stdin("\e")
run(PickerCommand, [])
TestUtils.feed_stdin('')
run(PickerCommand, [])
