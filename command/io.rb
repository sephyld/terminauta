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
    end
  end
end
