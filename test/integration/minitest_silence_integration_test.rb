# frozen_string_literal: true

require 'test_helper'

class MinitestSilenceIntegrationTest < IntegrationTest
  def test_noisy_tests_with_failure
    process = spawn_test_process(test_file: 'noisy_tests.rb').value

    refute_test_process_successful(process)
    refute_test_process_output_includes(process, "STDOUT noise")
    refute_test_process_output_includes(process, "STDERR noise")
    assert_test_process_output_includes(process, "6 runs, 6 assertions, 1 failures, 0 errors, 0 skips")
  end

  def test_noisy_test_in_verbose_mode
    process = spawn_test_process(
      test_file: 'noisy_tests.rb',
      arguments: ['--verbose', '-n', 'test_pass_with_noisy_stdout'],
    ).value

    assert_test_process_successful(process)
    assert_test_process_output_includes(process, "STDOUT noise")
    assert_test_process_output_includes(process, "1 runs, 1 assertions, 0 failures, 0 errors, 0 skips")
  end

  def test_noisy_test_in_fail_on_output
    process = spawn_test_process(
      test_file: 'noisy_tests.rb',
      arguments: ['--fail-on-output', '-n', 'test_pass_with_noisy_stdout'],
    ).value

    refute_test_process_successful(process)
    assert_test_process_output_includes(process, "The test unexpectedly wrote output to STDOUT or STDERR.")
    assert_test_process_output_includes(process, "STDOUT noise")
    assert_test_process_output_includes(process, "1 runs, 1 assertions, 1 failures, 0 errors, 0 skips")
  end
end
