# frozen_string_literal: true

# Example for the interactive picker (Terminauta::Command::Io#pick,
# colored through Ui#pick). Run it locally with:
#
#   ruby examples/pick.rb
#   or...
#   spinel -E examples/pick.rb
#
# Move the cursor with the arrow keys or j/k, select with enter or
# space, cancel with Ctrl-C or ESC.
require_relative '../terminauta'

class PickCommand < Terminauta::Command::ColoredCommand
  command_name 'pick'
  description 'Try out the interactive picker'

  def run
    fruit = pick 'Pick a fruit', ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'], color: :green
    if fruit.nil?
      say 'Cancelled', color: :yellow
      return 1
    end

    enjoy = yes? "Eat the #{fruit}?", default: true
    say "Enjoy your #{fruit}!", color: :green, bold: true if enjoy

    # You can also use hashes -> the returned value is the key
    fruit = pick 'Pick a fruit', { apple: 'Apple', banana: 'Banana' }, color: :red, format_choices: true
    if fruit.nil?
      say 'Cancelled', color: :yellow
      return 1
    end

    enjoy = yes? "Eat the #{fruit}?", default: true
    say "Enjoy your #{fruit}!", color: :green, bold: true if enjoy
    0
  end
end

exit PickCommand.execute(ARGV)
