# frozen_string_literal: true

# Shared helpers for the test/*.rb files. Lives in test/support/ so
# `spin test` (which runs test/*.rb) does not pick it up as a test.
module TestUtils
  # Replaces the process stdin with a pipe carrying +input+, so the
  # prompts read scripted answers instead of blocking on the user's
  # terminal. `spin test` gives the spinel and the CRuby run the same
  # stdin, so the input cannot come from a redirect: each run reopens
  # its own pipe with the same scripted answers.
  #
  # Under spinel a read that hits EOF sticks across reopen (the EOF
  # flag is not cleared), so a test that reads to EOF must be the last
  # one to feed stdin.
  def self.feed_stdin(input)
    reader, writer = IO.pipe
    writer.write(input)
    writer.close
    $stdin.reopen(reader)
  end
end
