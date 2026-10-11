# frozen_string_literal: true

# Validators (see command/validators/base_validator.rb): #validate
# returns the error messages, #validate! raises ValidationError with
# them, and declared validators run during parsing. Run under
# `spin test`, which diffs the spinel compiled output against a plain
# CRuby run of the same file: both must agree.
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

# BaseValidator itself: no errors by default, #validate! returns true.
base = Terminauta::Command::Validators::BaseValidator.new('anything')
puts "base_validate=#{base.validate.inspect}"
puts "base_validate_bang=#{base.validate!.inspect}"

# A validator collecting several messages.
class NameValidator < Terminauta::Command::Validators::BaseValidator
  def validate
    errors = []
    errors << 'is empty' if value.nil? || value.empty?
    errors << 'has a slash' if value.to_s.include?('/')
    errors << 'is too long' if value.to_s.length > 5
    errors
  end
end

puts "valid=#{NameValidator.new('ok').validate.inspect}"
puts "empty=#{NameValidator.new('').validate.inspect}"
puts "slash=#{NameValidator.new('a/b').validate.inspect}"
puts "two_errors=#{NameValidator.new('a/b/c/d').validate.inspect}"
puts "valid_bang=#{NameValidator.new('ok').validate!.inspect}"

begin
  NameValidator.new('a/b/c/d').validate!
rescue Terminauta::Command::Validators::ValidationError => e
  puts "validate_bang_error=#{e.message.inspect}"
end

# Declared validators run during parsing, on options and arguments.
class ValidatedCommand < Terminauta::Command::BaseCommand
  command_name 'validated'
  option :name, short: '-n', value: 'NAME', description: 'A name', validator: NameValidator
  argument :word, description: 'A word', validator: NameValidator

  def run
    puts "name=#{options['name'].inspect} word=#{arguments['word'].inspect} args=#{args.inspect}"
    0
  end
end

run(ValidatedCommand, ['-n', 'ok', 'word'])
run(ValidatedCommand, ['-n', 'a/b', 'word'])
run(ValidatedCommand, ['-n', 'ok', 'a/b'])
run(ValidatedCommand, ['-n', 'ok', 'a/b', 'extra'])

# build_validator: nil without a declared validator, an instance
# carrying the value with one.
option = Terminauta::Command::Option.new(:name, value: 'NAME', validator: NameValidator)
plain_option = Terminauta::Command::Option.new(:other, value: 'OTHER')
puts "build_class=#{option.build_validator('x').class.inspect}"
puts "build_value=#{option.build_validator('x').value.inspect}"
puts "build_nil=#{plain_option.build_validator('x').inspect}"

argument = Terminauta::Command::Argument.new(:word, validator: NameValidator)
puts "argument_build_value=#{argument.build_validator('y').value.inspect}"
puts "argument_value_name=#{argument.value_name.inspect}"
puts "argument_key=#{argument.key.inspect}"

# Values that materialize after parsing (defaults, prompt answers) are
# the command's to validate, reusing the declared validator through
# build_validator(value).validate!. The prompt is fed an empty answer
# (see TestUtils.feed_stdin), so it falls back to its default.
class PromptCommand < Terminauta::Command::BaseCommand
  command_name 'prompt'
  option :name, value: 'NAME', description: 'A name', validator: NameValidator

  def run
    name = options['name'] || ask('Enter a name', default: 'a/b')
    validator = self.class.options[0].build_validator(name)
    begin
      validator.validate!
      puts "name=#{name.inspect}"
    rescue Terminauta::Command::Validators::ValidationError => e
      puts "error: #{e.message}"
    end
    0
  end
end

run(PromptCommand, ['--name', 'ok'])
run(PromptCommand, ['--name', 'a/b'])
TestUtils.feed_stdin("\n")
run(PromptCommand, [])
