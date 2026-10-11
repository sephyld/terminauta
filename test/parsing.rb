# frozen_string_literal: true

# Option and argument parsing, delegated to the standard library
# OptionParser (see command/parsing.rb). These run under
# `spin test`, which diffs the spinel compiled output against a plain
# CRuby run of the same file: both must agree.
require_relative '../terminauta'

# A command with every option shape: a value taking short/long pair and
# two boolean flags to cluster.
class ValueCommand < Terminauta::Command::BaseCommand
  command_name 'value'
  option :name, short: '-n', value: 'NAME', description: 'A name'
  option :verbose, short: '-v', description: 'Verbose'
  option :force, short: '-f', description: 'Force'

  def run
    puts "name=#{options['name'].inspect} name_sym=#{options[:name].inspect} " \
         "verbose=#{options['verbose'].inspect} force=#{options['force'].inspect} args=#{args.inspect}"
    0
  end
end

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

run(ValueCommand, ['--name', 'foo', 'a'])
run(ValueCommand, ['--name=foo'])
run(ValueCommand, ['-n', 'foo'])
run(ValueCommand, ['-n=foo'])
run(ValueCommand, ['-nfoo'])
run(ValueCommand, ['-v', '-f'])
run(ValueCommand, ['-vf'])
run(ValueCommand, ['-vfn', 'foo'])
run(ValueCommand, ['-vfn=x'])
run(ValueCommand, ['-v=x'])
run(ValueCommand, ['--name'])
run(ValueCommand, ['-n'])
run(ValueCommand, ['--bad'])
run(ValueCommand, ['-x'])
run(ValueCommand, ['a', '--', '-v', 'b'])
run(ValueCommand, ['-'])
run(ValueCommand, ['--help'])
run(ValueCommand, ['--help', '--bad'])
run(ValueCommand, ['--bad', '--help'])
run(ValueCommand, ['--help=x'])
run(ValueCommand, ['-vh'])

# Subcommand dispatch: the parent stops parsing at the subcommand token.
class SubCommand < Terminauta::Command::BaseCommand
  command_name 'outer sub'
  option :verbose, short: '-v', description: 'Verbose'

  def run
    puts "sub verbose=#{options['verbose'].inspect} args=#{args.inspect} " \
         "parent_name=#{parent_command.options['name'].inspect}"
    0
  end
end

class OuterCommand < Terminauta::Command::BaseCommand
  command_name 'outer'
  option :name, short: '-n', value: 'NAME', description: 'A name'
  option :verbose, short: '-v', description: 'Verbose'
  subcommand 'sub', SubCommand

  def run
    puts "outer name=#{options['name'].inspect} verbose=#{options['verbose'].inspect} args=#{args.inspect}"
    0
  end
end

run(OuterCommand, ['-n', 'x', 'sub', '-v', 'a'])
run(OuterCommand, ['sub'])
run(OuterCommand, ['--', 'sub'])
run(OuterCommand, ['-n', 'sub'])
run(OuterCommand, ['sub', '-n=x'])
run(OuterCommand, ['-n=x', 'sub', '-v'])
run(OuterCommand, ['-vn', 'sub'])
run(OuterCommand, ['-vn=x', 'sub'])

# Declared validators run during parsing; a missing declared argument is
# reported before #run.
class PresentValidator < Terminauta::Command::Validators::BaseValidator
  def validate
    value.to_s.empty? ? ['is empty'] : []
  end
end

class ValidatedCommand < Terminauta::Command::BaseCommand
  command_name 'validated'
  option :name, short: '-n', value: 'NAME', description: 'A name', validator: PresentValidator
  argument :word, description: 'A word', validator: PresentValidator

  def run
    puts "name=#{options['name'].inspect} word=#{arguments['word'].inspect}"
    0
  end
end

run(ValidatedCommand, ['-n', 'ok', 'word'])
run(ValidatedCommand, ['-n', '', 'word'])
run(ValidatedCommand, ['-n=ok', ''])
run(ValidatedCommand, ['-n=ok'])

# The built-in --color/--no-color flags of a ColoredCommand, including
# the shadowing by a declared option on the same flag.
class ColorCommand < Terminauta::Command::ColoredCommand
  command_name 'color'
  option :verbose, short: '-v', description: 'Verbose'

  def run
    puts "override=#{Terminauta::Command::Ui.color_override.inspect}"
    0
  end
end

class ShadowColorCommand < Terminauta::Command::ColoredCommand
  command_name 'shadow'
  option :color, value: 'COLOR', description: 'Shadowed color'

  def run
    puts "color=#{options['color'].inspect} override=#{Terminauta::Command::Ui.color_override.inspect}"
    0
  end
end

Terminauta::Command::Ui.color_override = nil
run(ColorCommand, ['--color'])
run(ColorCommand, ['--no-color'])
run(ColorCommand, ['--color=x'])
Terminauta::Command::Ui.color_override = nil
run(ShadowColorCommand, ['--color=red'])
run(ShadowColorCommand, ['--color'])
run(ShadowColorCommand, ['--no-color=x'])

# A duplicate option declaration is rejected when the parser is built.
class DuplicateCommand < Terminauta::Command::BaseCommand
  command_name 'duplicate'
  option :name, short: '-n', value: 'NAME', description: 'A name'
  option :full, short: '-n', long: '--full', description: 'Same short flag'

  def run
    0
  end
end

run(DuplicateCommand, [])
