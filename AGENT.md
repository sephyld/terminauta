# Terminauta

This is a [ruby spinel](https://github.com/matz/spinel) command line framework.

## Commands
- Run the tests using `spin test` (test/*.rb, spinel output diffed against plain ruby)

## Structure
- `terminauta.rb`: library entry point (require "terminauta"), requires the command/ files
- `command/base_command.rb`: the plain class to inherit from
- `command/colored_command.rb`: BaseCommand + colored output (Ui)
- `command/class_methods.rb`: class level DSL (description, option, subcommand, execute)
- `command/option.rb`: Option class: declaration kwargs and help labels
- `command/argument.rb`: Argument class: declared positional arguments
- `command/parsing.rb`: ARGV -> args/options via optparse, stops at subcommand tokens
- `command/help.rb`: help rendering
- `command/dispatch.rb`: subcommand delegation in #call
- `command/state.rb`: State singleton: process wide --color/--no-color choice
- `command/io.rb`: plain output (#say, #ask) and yes/no prompts (#yes?)
- `command/ui.rb`: colored output and the --color/--no-color flags
- `command/error.rb`: Command::Error, Command::OptionError
- `command/validators/base_validator.rb`: Validators::BaseValidator and ValidationError

## Limitations
Ruby spinel has some limitations and some Ruby features are not vailable. There are:
- No eval: eval, instance_eval("str"), class_eval("str") (the block forms are compiled)
- No dynamic metaprogramming: method_missing, define_method / send with a runtime-computed name (a literal send(:name) and literal define_method do work)
- No encoding: assumes UTF-8/ASCII
- No general lambda calculus: deeply nested -> x { } with [] calls
- Buggy runtime introspection: `Module#include?` on a class only known at
  runtime answers false where MRI answers true (use `ancestors.include?`
  instead); `Module#method_defined?` needs a compile-time-known class and
  a literal method name
