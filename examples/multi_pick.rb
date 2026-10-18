# frozen_string_literal: true

# Example for the interactive multi-select picker (Terminauta::Command::Io#pick
# with multi: true, colored through Ui#pick). Run it locally with:
#
#   ruby examples/multi_pick.rb
#   or...
#   spinel -E examples/multi_pick.rb
#
# Move the cursor with the arrow keys or j/k, toggle choices with
# space, confirm with enter, cancel with Ctrl-C or ESC.
require_relative '../terminauta'

class MultiPickCommand < Terminauta::Command::ColoredCommand
  command_name 'multipick'
  description 'Try out the interactive multi-select picker'

  def run
    fruits = pick 'Pick your fruits', ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'], multi: true, color: :green
    if fruits.nil?
      say 'Cancelled', color: :yellow
      return 1
    end

    say "You picked: #{fruits.join(', ')}", color: :green, bold: true

    # You can also use hashes -> the returned values are the keys
    sizes = pick 'Pick your sizes', { s: 'Small', l: 'Large', xl: 'Extra large' }, multi: true, color: :red, format_choices: true
    if sizes.nil?
      say 'Cancelled', color: :yellow
      return 1
    end

    say "You picked: #{sizes.join(', ')}", color: :green, bold: true
    0
  end
end

exit MultiPickCommand.execute(ARGV)
