# frozen_string_literal: true

# Plain terminal input/output (see command/io.rb): #say prints on
# stdout, #yes? and #ask print a prompt and read stdin. The prompts
# are fed scripted answers (see TestUtils.feed_stdin): `spin test`
# passes its own stdin through to both the spinel and the CRuby run
# and the two share it, so the tests cannot wait on the caller's
# terminal. The output is diffed against a plain CRuby run of the same
# file: both must agree.
require_relative '../terminauta'
require_relative 'support/test_utils'

class IoCommand < Terminauta::Command::BaseCommand
  command_name 'io'

  def run
    say 'say message'
    say
    say 'say with ignored options', color: :red, bold: true
    puts "yes=#{yes?('Remove it?').inspect}"
    puts "yes_default=#{yes?('Install it?', default: true).inspect}"
    puts "ask=#{ask('Enter a name').inspect}"
    puts "ask_default=#{ask('Enter a path', default: '/usr/local').inspect}"
    0
  end
end

# Scripted answers for the prompts in #run: y, n, a free-form answer
# and an empty line, which falls back to the default.
TestUtils.feed_stdin("y\nn\nAlice\n\n")

puts "status=#{IoCommand.execute([]).inspect}"
