# frozen_string_literal: true

# Subcommand dispatch (see command/dispatch.rb) and the .execute entry
# point (see command/class_methods.rb): the parent stops parsing at a
# subcommand token and hands the remaining ARGV to the subcommand, each
# level parses only its own options, and .execute maps the command's
# result to a process exit status. Run under `spin test`, which diffs
# the spinel compiled output against a plain CRuby run of the same
# file: both must agree.
require_relative '../terminauta'

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

class InnerCommand < Terminauta::Command::BaseCommand
  command_name 'outer inner'
  option :loud, short: '-l', description: 'Loud'

  def run
    puts "inner loud=#{options['loud'].inspect} args=#{args.inspect} " \
         "parent=#{parent_command.class.command_name.inspect} " \
         "parent_name=#{parent_command.options['name'].inspect}"
    0
  end
end

class OuterCommand < Terminauta::Command::BaseCommand
  command_name 'outer'
  option :name, short: '-n', value: 'NAME', description: 'A name'
  subcommand 'inner', InnerCommand

  def run
    puts "outer name=#{options['name'].inspect} args=#{args.inspect} root=#{parent_command.nil?}"
    0
  end
end

run(OuterCommand, ['-n', 'x', 'inner', '-l', 'a'])
run(OuterCommand, ['inner'])
run(OuterCommand, ['--', 'inner'])
run(OuterCommand, ['-n', 'inner'])
run(OuterCommand, ['inner', '-n', 'x'])
run(OuterCommand, ['-n', 'x', 'inner', 'extra', 'args'])

# .execute maps the result of #run to the exit status.
class StatusCommand < Terminauta::Command::BaseCommand
  command_name 'status'

  def run
    3
  end
end

class NoStatusCommand < Terminauta::Command::BaseCommand
  command_name 'nostatus'

  def run
    1
  end
end

# .execute maps the result of #run to the exit status: the Integer #run
# returns, 0 for anything else, 1 when an OptionError or a
# ValidationError is reported (the report itself goes to stderr). The
# calls use literal class receivers: spinel only emits the singleton
# method for a class it sees called, and no dispatch ever targets
# BaseCommand.execute itself.
puts '-- execute status'
puts "status=#{StatusCommand.execute([]).inspect}"
puts '-- execute nostatus'
puts "status=#{NoStatusCommand.execute([]).inspect}"
puts '-- execute outer --bad'
puts "status=#{OuterCommand.execute(['--bad']).inspect}"
puts '-- execute outer inner --bad'
puts "status=#{OuterCommand.execute(['inner', '--bad']).inspect}"

# Color support must be uniform along a dispatch chain (see
# command/colored_command.rb): a ColoredCommand under a plain parent
# or a plain subcommand under a ColoredCommand is rejected.
class ColoredChild < Terminauta::Command::ColoredCommand
  command_name 'plainparent colored'

  def run
    0
  end
end

class PlainParent < Terminauta::Command::BaseCommand
  command_name 'plainparent'
  subcommand 'colored', ColoredChild

  def run
    0
  end
end

class PlainChild < Terminauta::Command::BaseCommand
  command_name 'coloredparent plain'

  def run
    0
  end
end

class ColoredParent < Terminauta::Command::ColoredCommand
  command_name 'coloredparent'
  subcommand 'plain', PlainChild

  def run
    0
  end
end

run(PlainParent, ['colored'])
run(ColoredParent, ['plain'])
run(ColoredParent, ['--color', 'plain'])
Terminauta::Command::Ui.color_override = nil
