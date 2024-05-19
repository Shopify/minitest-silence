# frozen_string_literal: true

require "minitest/autorun"

class NoisyTest < Minitest::Test
  def test_pass_with_noisy_stdout
    $stdout.puts("STDOUT noise")
    pass
  end

  def test_pass_with_noisy_stderr_pass
    $stderr.puts("STDERR noise")
    pass
  end

  def test_fail_with_noise
    puts("STDOUT noise")
    flunk
  end

  def test_noisy_subprocess
    assert system("echo 'STDOUT noise'")
  end

  def test_long_line_output
    puts("*" * 500)
    pass
  end

  def test_output_with_empty_lines
    puts("STDOUT noise line one")
    puts
    puts("STDOUT noise line three")
    pass
  end
end
