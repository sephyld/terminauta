# frozen_string_literal: true

# Help rendering (see command/help.rb) and the class level DSL
# defaults (see command/class_methods.rb): usage, command_name and
# description, and the subcommands, arguments and options listings.
# Run under `spin test`, which diffs the spinel compiled output
# against a plain CRuby run of the same file: both must agree.
require_relative '../terminauta'

class AddCommand < Terminauta::Command::BaseCommand
  command_name 'list add'
  description 'Add an item'
  usage 'list add [options] NAME'
  argument :name, description: 'Name of the item to add'
  option :priority, value: 'PRIORITY', description: 'Priority of the item'

  def run
    0
  end
end

class ListCommand < Terminauta::Command::BaseCommand
  command_name 'list'
  description 'List the items'
  option :verbose, short: '-v', description: 'Print extra output'
  option :output, short: '-o', value: 'FORMAT', description: 'Output format'
  subcommand 'add', AddCommand

  def run
    0
  end
end

class PlainCommand < Terminauta::Command::BaseCommand
  def run
    0
  end
end

puts ListCommand.new([]).help
puts '---'
puts AddCommand.new([]).help
puts '---'
puts PlainCommand.new([]).help
puts '---'

# command_name defaults to the class name downcased, with a trailing
# '::Command' namespace part stripped; usage defaults to
# '<name> [options] [ARGS]'.
module Nested
  class Command < Terminauta::Command::BaseCommand
    def run
      0
    end
  end

  class Deep
    class Command < Terminauta::Command::BaseCommand
      def run
        0
      end
    end
  end
end

puts "nested=#{Nested::Command.command_name.inspect}"
puts "deep=#{Nested::Deep::Command.command_name.inspect}"
puts "plain=#{PlainCommand.command_name.inspect}"
puts "explicit=#{ListCommand.command_name.inspect}"
puts "usage_unset=#{ListCommand.usage.inspect}"
puts "usage_set=#{AddCommand.usage.inspect}"
puts "description=#{ListCommand.description.inspect}"
puts "description_unset=#{PlainCommand.description.inspect}"

# Option and Argument declarations: labels, keys and placeholders.
verbose = Terminauta::Command::Option.new(:verbose, short: '-v', description: 'Print extra output')
output = Terminauta::Command::Option.new(:output, short: '-o', value: 'FORMAT', description: 'Output format')
custom = Terminauta::Command::Option.new(:name, long: '--nombre', value: 'NAME')
puts "label_boolean=#{verbose.label.inspect} boolean=#{verbose.boolean?.inspect}"
puts "label_value=#{output.label.inspect} boolean=#{output.boolean?.inspect}"
puts "long_default=#{verbose.long.inspect}"
puts "long_custom=#{custom.long.inspect} label=#{custom.label.inspect}"

argument = Terminauta::Command::Argument.new(:name, description: 'A name')
puts "argument_value_name=#{argument.value_name.inspect} key=#{argument.key.inspect}"
