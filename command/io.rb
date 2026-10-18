# frozen_string_literal: true

module Terminauta
  module Command
    # Terminal input/output helpers included by BaseCommand, so every
    # command can print messages and ask yes/no questions.
    #
    # The methods take the same options as their colored counterparts in
    # Ui (color:/bold:) but accept and ignore any option: colors are a
    # ColoredCommand concern, so code written for a colored command also
    # runs unchanged on a plain one, just without the colors.
    module Io
      # Prints +message+ on stdout:
      #
      #   say 'Installed myapp'
      def say(message = '', **_options)
        $stdout.puts message.to_s
      end

      # Asks a yes/no question on stdout and reads the answer from stdin.
      # Returns true for y/yes, false for n/no and +default+ on an empty
      # answer or EOF; anything else is asked again.
      #
      #   exit 1 unless yes? "Remove #{name}?"
      def yes?(question, default: false, **_options)
        hint = default ? '[Y/n]' : '[y/N]'
        loop do
          print "#{question} #{hint} "
          $stdout.flush
          answer = $stdin.gets
          return default if answer.nil?

          answer = answer.strip.downcase
          return default if answer.empty?
          return true if answer.start_with?('y')
          return false if answer.start_with?('n')
        end
      end

      # Asks a question on stdout and reads a free-form answer from stdin.
      # Returns the user's input stripped of whitespace, or +default+ on an
      # empty answer or EOF.
      #
      #   name = ask "Enter your name"
      #   path = ask "Enter path", default: "/usr/local"
      def ask(question, default: '', **_options)
        hint = default.empty? ? '' : " (#{default})"
        print "#{question}#{hint} "
        $stdout.flush
        answer = $stdin.gets
        return default if answer.nil?

        answer = answer.strip
        return default if answer.empty?
        answer
      end

      # Shows an interactive picker on stdout and returns the selected
      # choice: the question on one line, then the choices with a '>'
      # cursor on the current one. The arrow keys or 'j'/'k' move the
      # cursor (wrapping around at both ends), enter or space selects,
      # and Ctrl-C, ESC or EOF cancel, returning nil. Keys that are not
      # part of the picker are ignored. While picking, stdin is put in
      # raw mode (no echo, single keystrokes) and restored afterwards;
      # on a TTY the list is redrawn in place, otherwise each state is
      # printed again. Raises ArgumentError when +choices+ is empty.
      #
      # +choices+ is a list of values to pick from, or a Hash: the
      # values are the labels shown in the list and the keys are the
      # values returned, so picking a label returns its key.
      #
      #   fruit = pick 'Pick a fruit', ['Apple', 'Banana', 'Cherry']
      #   size = pick 'Pick a size', { s: 'Small', l: 'Large' }
      def pick(question, choices, **_options)
        raise ArgumentError, 'pick needs at least one choice' if choices.empty?

        labels = choices.is_a?(Hash) ? choices.values : choices
        values = choices.is_a?(Hash) ? choices.keys : choices

        $stdout.puts question.to_s
        render_picker_choices(labels, 0, false)
        index = with_picker_terminal { run_picker_loop(labels) }
        index.nil? ? nil : values[index]
      end

      private

      # The picker loop: reads keys until one selects or cancels,
      # redrawing the choices on every move. Returns the selected index,
      # or nil when cancelled.
      def run_picker_loop(choices)
        cursor = 0
        loop do
          case read_picker_key
          when :up
            cursor = (cursor - 1) % choices.length
            render_picker_choices(choices, cursor, true)
          when :down
            cursor = (cursor + 1) % choices.length
            render_picker_choices(choices, cursor, true)
          when :select
            return cursor
          when :cancel
            return nil
          end
        end
      end

      # Reads one key from stdin and translates it to a picker action:
      # :up, :down, :select, :cancel, or nil for keys to ignore. Keys
      # are read byte by byte with IO#getbyte (spinel implements neither
      # IO#getch nor IO#raw): enter is CR or LF, space selects, 'j'/'k'
      # move down/up, Ctrl-C cancels, and ESC starts an escape sequence
      # (the arrow keys) or cancels when it stands alone.
      def read_picker_key
        byte = $stdin.getbyte
        return :cancel if byte.nil?

        case byte
        when 3 then :cancel
        when 10, 13, 32 then :select
        when 106 then :down
        when 107 then :up
        when 27 then read_picker_escape
        end
      end

      # Reads the rest of an escape sequence started by ESC: the arrow
      # keys are CSI ('\e[A'/'\e[B') or SS3 ('\eOA'/'\eOB') sequences.
      # Returns :up/:down for them, nil for any other sequence, and
      # :cancel for a lone ESC (no byte follows within a short timeout).
      def read_picker_escape
        return :cancel unless picker_input_pending?

        byte = $stdin.getbyte
        return :cancel if byte.nil?
        return nil unless [91, 79].include?(byte)

        case $stdin.getbyte
        when 65 then :up
        when 66 then :down
        end
      end

      # Whether more input is immediately available on stdin, used to
      # tell a lone ESC (cancel) from the start of an escape sequence.
      def picker_input_pending?
        !IO.select([$stdin], nil, nil, 0.05).nil?
      end

      # Prints the choices with the cursor marker on the choice at
      # +cursor+. On a redraw on a TTY, moves the cursor up over the
      # previous rendering and clears it first, so the list is updated
      # in place; otherwise (first render, or stdout not a TTY) the
      # choices are simply printed again.
      def render_picker_choices(choices, cursor, redraw)
        $stdout.print "\e[#{choices.length}A\e[J" if redraw && $stdout.tty?
        choices.each_with_index do |choice, index|
          marker = index == cursor ? '>' : ' '
          $stdout.puts "#{marker} #{choice}"
        end
        $stdout.flush
      end

      # Runs the block with stdin in raw mode (no echo, no line
      # buffering), so the picker reads single keystrokes, and restores
      # the previous terminal settings afterwards. Raw mode needs a real
      # terminal: on a pipe (tests, redirects) the block runs unchanged.
      # stty is used instead of io/console because spinel implements
      # neither IO#raw nor IO#getch.
      def with_picker_terminal
        return yield unless $stdin.tty?

        saved = `stty -g`.chomp
        return yield if saved.empty?

        # 'raw' also switches off output post-processing (opost): without
        # it every newline prints without a carriage return and the redraw
        # tabs sideways at each keystroke, so opost is switched back on.
        system('stty', 'raw', 'opost', '-echo')
        begin
          yield
        ensure
          system('stty', saved)
        end
      end
    end
  end
end
