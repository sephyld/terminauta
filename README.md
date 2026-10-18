# Terminauta

`terminauta` is a small reusable CLI framework for ruby, written to also
run under [ruby spinel](https://github.com/matz/spinel). It provides
option parsing (delegated to the stdlib `optparse`), positional
arguments, subcommand dispatch, help rendering and colored output.
The name mashes terminal and nauta (Latin for sailor): someone or
something that sails through the terminal.

## Installation

> [!WARNING]
> Work in progress: how to install terminauta as a dependency and
> require it from another project is not documented yet.

## Quick start

Inherit from `Terminauta::Command::BaseCommand` (or `ColoredCommand`) and
use the class level DSL:

```ruby
class Todo::Command < Terminauta::Command::ColoredCommand
  command_name 'todo'
  description 'Manage a todo list'

  option :verbose, description: 'Print extra output'
  subcommand 'add', Todo::Commands::Add
  subcommand 'rm', Todo::Commands::Rm
  subcommand 'ls', Todo::Commands::Ls

  def run
    # args (Array) and options (Hash) are parsed and available here
    # return an Integer to use it as the process exit status
  end
end

exit Todo::Command.execute(ARGV)
```

There are two classes to inherit from:

| Class | Description |
| --- | --- |
| `Terminauta::Command::BaseCommand` | Plain: options, args, help, subcommand dispatch and uncolored `#say`/`#yes?`/`#ask`/`#pick` (Io). No color support at all |
| `Terminauta::Command::ColoredCommand` | BaseCommand plus `#colorize`/`#color_enabled?`, `color:`/`bold:` options in `#say`/`#yes?`/`#ask`/`#pick` and the built-in `--color`/`--no-color` flags (see below) |

### Class level DSL

| Method | Description |
| --- | --- |
| `description text` | One line description shown in help output |
| `usage text` | Usage line, defaults to `'<name> [options] [ARGS]'` |
| `command_name name` | Name shown in help/errors. Defaults to the class name downcased with a trailing `::Command` stripped (`Todo::Command` -> `todo`). Subcommands should set it explicitly, e.g. `'todo add'` |
| `option name, **kwargs` | Declare an option: `option :name, short: '-n', value: 'NAME', description: '...', validator: NameValidator`. `name` is the options hash key; `long:` defaults to `--<name>`; a non-nil `value:` makes the option take an argument, otherwise it is a boolean flag |
| `argument name, **kwargs` | Declare a positional argument, required by definition: `argument :name, description: '...', validator: NameValidator`. `name` is the key in the parsed `#arguments` hash and doubles as the placeholder in help/error messages, upcased (`:name` -> `NAME`). Declared arguments are matched against the parsed value in declaration order before `#run`; a missing one exits 1 with `todo add: missing NAME` plus the `--help` hint. Undeclared positional arguments are not checked and stay in `#args` |
| `subcommand name, klass` | Register a subcommand class under `name` |

`-h/--help` is built in on every command; `--color`/`--no-color` only on
`ColoredCommand`.

### Instance API

| Method | Description |
| --- | --- |
| `#args` | Positional arguments left after option parsing |
| `#arguments` | Parsed arguments hash, keyed by the declared argument name (`argument :name` -> `arguments['name']`), mirroring `#options` |
| `#options` | Parsed options hash, keyed by the declared option name (`option :url` -> `options['url']`) |
| `#run` | Override with the command behavior. An Integer return value becomes the process exit status; anything else means success |
| `#call` | Entry point: prints help when requested, delegates to a subcommand, otherwise checks declared arguments and runs |
| `#parent_command` | The command instance this one was dispatched from, nil on the root command |
| `#say message, **options` | Prints a message on stdout. Extra options (`color:`/`bold:`) are accepted and ignored: same signature as the colored one |
| `#yes? question, default:, **options` | Asks a yes/no question on stdout and reads the answer from stdin (see below). Extra options are accepted and ignored |
| `#ask question, default:, **options` | Asks a question on stdout and reads a free-form answer from stdin (see below). Extra options are accepted and ignored |
| `#pick question, choices, multi:, **options` | Shows an interactive picker on stdout and returns the selected choice (see below); with `multi: true` the picker becomes a multi-select and returns an Array of the selected choices. Extra options are accepted and ignored: same signature as the colored one |
| `.execute(argv, parent_command = nil)` | Builds the command from ARGV, runs it, returns a process exit status. `OptionError`s and `ValidationError`s are reported on stderr. `parent_command` is passed by the parent's dispatch |

Both `#options` and `#arguments` are keyed by string and by symbol:
`options['url']` and `options[:url]` are the same value.

ColoredCommand adds:

| Method | Description |
| --- | --- |
| `#say message, color:, bold:` | Overrides the plain `#say`: prints the message on stdout, colored when requested and enabled |
| `#yes? question, default:, color:, bold:` | Overrides the plain `#yes?`: colors the question when requested, then asks it plainly |
| `#ask question, default:, color:, bold:` | Overrides the plain `#ask`: colors the question when requested, then asks it plainly |
| `#pick question, choices, color:, bold:, format_choices:, multi:` | Overrides the plain `#pick`: colors the question when requested, then picks plainly; with `format_choices: true` the choice labels get the same color/bold codes; with `multi: true` the picker selects several choices and returns them as an Array |
| `#colorize text, color:, bold:` | Returns `text` wrapped in ANSI codes when colors are enabled, `text` itself otherwise |
| `#color_enabled?` | Whether colored output is enabled (see below) |

### Option parsing

Token parsing is delegated to `optparse`, the option parser in the
standard library. The declared options are registered on an
`OptionParser` per command; the framework keeps the subcommand split,
the `#options`/`#args` hashes and the error messages.

- `--opt value`, `--opt=value`, `-o value`, `-o=value`, `-ovalue`
- Clustered short flags: `-ft` is equivalent to `-f -t`; an inline `=value` attaches to the last flag of a cluster (`-ft=AAA`)
- Boolean flags: `--verbose` -> `options['verbose'] = true`
- `--` puts every following token in `args`
- `-h/--help` stops parsing: following words are neither parsed nor reported (so `--help --bad` still shows the help)
- Long flags are matched exactly: no abbreviation (`--verb` does not mean `--verbose`), on spinel by subset and under MRI through `require_exact`
- Unknown options raise `Command::OptionError`, reported as
  `todo: unknown option "--bad"` plus a `Try 'todo --help'` hint, exit status 1
- `--color`/`--no-color` are built in on `ColoredCommand`: they force
  colors on or off for the whole process (so they work at any subcommand
  level) and do not take a value. A command declaring its own option with
  the same long flag shadows the built-in one; on a plain `BaseCommand`
  they are unknown options

### Subcommands

Subcommands are `BaseCommand` (or `ColoredCommand`) subclasses registered
on their parent with `subcommand`. When parsing hits a bare token naming a
registered subcommand, the parent stops parsing and hands the remaining
ARGV to that subcommand's `execute`, so each level parses only its own
options:

```ruby
module Todo
  module Commands
    class Add < Terminauta::Command::ColoredCommand
      command_name 'todo add'
      description 'Add an item to the list'
      usage 'todo add [options] NAME'

      argument :name, description: 'Name of the item to add'
      option :priority, value: 'PRIORITY', description: 'Priority of the item (defaults to normal)'
      option :due, value: 'DATE', description: 'Due date of the item'

      def run
        # arguments[:name] is guaranteed to be present here: a missing
        # declared argument is rejected before #run
        # ...
      end
    end
  end
end
```

Options declared on the parent are not visible to the subcommand; each level
only sees its own options. A subcommand's `#parent_command` holds the
command instance it was dispatched from (nil on the root command).

Color support must be uniform along a dispatch chain, so a `--color`/
`--no-color` flag parsed by one level is meaningful for all of them: a
`ColoredCommand` raises `Terminauta::Command::Error` when it is dispatched
under a command without color support, or when it dispatches to a
subcommand without it. Plain `BaseCommand` trees are not restricted.

### Validators

`option` and `argument` accept a `validator:` keyword naming a
`Terminauta::Command::Validators::BaseValidator` subclass. A validator is
instantiated with the parsed value; its `#validate` returns the list of
error messages (empty when the value is valid) and `#validate!` raises
`Validators::ValidationError` with the collected messages instead.

```ruby
class NameValidator < Terminauta::Command::Validators::BaseValidator
  def validate
    return ['missing NAME'] if value.nil? || value.empty?

    errors = []
    errors << "Name cannot contain '/' characters" if value.include?('/')
    errors
  end
end

class Add < Terminauta::Command::ColoredCommand
  argument :name, description: 'Name of the application', validator: NameValidator
  option :url, value: 'URL', description: 'URL of the application', validator: UrlValidator
  # ...
end
```

Declared validators run during parsing, as soon as the value is
assigned: the first invalid one aborts the command with
`ValidationError`, reported as `<command>: <messages>`, exit status 1.
Values that materialize after parsing (defaults, prompt answers) are the
command's to validate, e.g. by reusing the declared validator through
`build_validator(value).validate!`.

### Colored output and prompts

`#say`, `#yes?`, `#ask` and `#pick` are part of the base (Io): every
command can print messages, ask questions and pick from a list, without
colors. Their plain versions
accept the same options as the colored ones and ignore them, so code
written for a colored command also runs unchanged on a plain one. Color
support is the `ColoredCommand` extra (a plain `BaseCommand` rejects
`--color`/`--no-color` as unknown options): its `#say` colors the
message and its `#yes?` the question, only when colors are enabled,
through the `color:`/`bold:` options. `#pick` colors the question the
same way and, with `format_choices: true`, the choice labels too.

```ruby
def run
  say "add: installed #{args[0].inspect}", color: :green, bold: true

  return 1 unless yes? "Remove #{args[0]}?"

  say 'Aborted', color: :yellow
end
```

`#colorize` does the same wrapping without printing, e.g. for composing
larger strings. Colors available: `:black`, `:red`, `:green`, `:yellow`,
`:blue`, `:magenta`, `:cyan` and `:white`, plus `bold: true`.

Colors are enabled automatically when stdout is a TTY. `--color` forces
them on, `--no-color` or a non-empty `NO_COLOR` environment variable
forces them off; the command line flag wins over the environment. The
decision is process wide, so `todo --color add my-item` colors the
subcommand output too.

`#yes?` prints `question [y/N]` (or `[Y/n]` with `default: true`),
flushes stdout and reads a line from stdin. `y`/`yes` answers true,
`n`/`no` answers false, an empty answer or EOF falls back to `default`,
and anything else re-asks. Answers are case insensitive.

`#ask` prints `question` (with ` (default)` appended when a non-empty
default is given), flushes stdout and reads a line from stdin, returning
the answer stripped of whitespace, or `default` on an empty answer or
EOF.

`#pick` shows an interactive picker: the question on one line, then the
choices with a `>` cursor on the current one. The arrow keys or `j`/`k`
move the cursor (wrapping around at both ends), enter or space selects
and returns the chosen value, and Ctrl-C, ESC or EOF cancel, returning
nil. Keys that are not part of the picker are ignored. `choices` is a
list of values, or a Hash whose values are the labels shown and whose
keys are the values returned, so picking a label returns its key:
`pick 'Size', { s: 'Small', l: 'Large' }` shows Small and Large and
returns `:s` or `:l`. While picking, stdin is put in raw mode (no echo,
single keystrokes) and restored afterwards; on a TTY the list is redrawn
in place, otherwise each state is printed again. An empty `choices`
raises `ArgumentError`.

With `multi: true` the picker becomes a multi-select: each choice gets
a `[x]`/`[ ]` checkbox, space toggles the one under the cursor, enter
confirms and returns the selected values as an Array in choice order
(an empty Array when nothing is picked), and Ctrl-C, ESC or EOF cancel,
returning nil: `pick 'Fruits', ['Apple', 'Banana'], multi: true` returns
e.g. `['Apple']`. A Hash works the same way: the Array holds the keys
of the picked labels.

### Errors

| Class | Raised when |
| --- | --- |
| `Terminauta::Command::Error` | A `ColoredCommand` is dispatched under a command without color support, or dispatches to a subcommand without it |
| `Terminauta::Command::OptionError` | ARGV cannot be matched against the declared options (unknown option, missing or needless value) |
| `Terminauta::Command::MissingArgumentError` | A declared argument has no value in `args`. Subclass of `OptionError` |
| `Terminauta::Command::Validators::ValidationError` | A declared validator rejects a parsed value |

`.execute` rescues `OptionError` (including `MissingArgumentError`) and
`ValidationError`, reports them on stderr — option errors with a
`Try '<command> --help'` hint — and returns exit status 1.

### Layout

```
terminauta.rb              # entry point: requires the files below
command/
    ├── base_command.rb    # the plain class to inherit from
    ├── colored_command.rb # BaseCommand + colored output (Ui)
    ├── class_methods.rb   # class level DSL (description, option, subcommand, execute)
    ├── option.rb          # Option class: declaration kwargs and help labels
    ├── argument.rb        # Argument class: declared positional arguments
    ├── parsing.rb         # ARGV -> args/options via optparse, stops at subcommand tokens
    ├── help.rb            # help rendering
    ├── dispatch.rb        # subcommand delegation in #call
    ├── state.rb           # State singleton: process wide --color/--no-color choice
    ├── io.rb              # plain output (#say, #ask), yes/no prompts (#yes?) and the interactive picker (#pick, single or multi select)
    ├── ui.rb              # colored output, the colored #pick and the --color/--no-color flags
    ├── error.rb           # Command::Error, Command::OptionError
    └── validators/
        └── base_validator.rb # Validators::BaseValidator and ValidationError
```

The framework only uses spinel-safe Ruby: no `eval`, no `method_missing`,
no dynamically defined methods.
