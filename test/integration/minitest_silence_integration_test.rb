# frozen_string_literal: true

require "test_helper"

class MinitestSilenceIntegrationTest < IntegrationTest
  def test_off_by_default
    old_ci = ENV["CI"]
    ENV["CI"] = nil

    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      arguments: ["-n", "test_pass_with_noisy_stdout", "--seed", "123"],
    ).value

    assert_test_process_successful(process)
    assert_equal <<~EOM, normalize_output(process.stdout)
      Run options: -n test_pass_with_noisy_stdout --seed 123

      # Running:

      STDOUT noise
      .

      Finished in 0.012s, 0.012 runs/s, 0.012 assertions/s.

      1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
    EOM
  ensure
    ENV["CI"] = old_ci
  end

  def test_enable_silence
    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      arguments: ["--enable-silence", "-n", "test_pass_with_noisy_stdout", "--seed", "123"],
    ).value

    assert_test_process_successful(process)
    assert_equal <<~EOM, normalize_output(process.stdout)
      Run options: --enable-silence -n test_pass_with_noisy_stdout --seed 123

      # Running:

      .

      Finished in 0.012s, 0.012 runs/s, 0.012 assertions/s.

      1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
    EOM
  end

  def test_env_enable_silence_in_ci
    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      arguments: ["-n", "test_pass_with_noisy_stdout", "--seed", "123"],
      env: { "CI" => "yes" },
    ).value

    assert_test_process_successful(process)
    assert_equal <<~EOM, normalize_output(process.stdout)
      Run options: -n test_pass_with_noisy_stdout --seed 123

      # Running:

      .

      Finished in 0.012s, 0.012 runs/s, 0.012 assertions/s.

      1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
    EOM
  end

  def test_noisy_tests_with_failure
    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      env: { "CI" => "yes" },
    ).value

    refute_test_process_successful(process)
    refute_test_process_output_includes(process, "STDOUT noise")
    refute_test_process_output_includes(process, "STDERR noise")
    assert_test_process_output_includes(process, "6 runs, 6 assertions, 1 failures, 0 errors, 0 skips")
  end

  def test_noisy_test_in_verbose_mode
    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      arguments: ["--verbose", "-n", "test_pass_with_noisy_stdout"],
      env: { "CI" => "yes" },
    ).value

    assert_test_process_successful(process)
    assert_test_process_output_includes(process, "STDOUT noise")
    assert_test_process_output_includes(process, "1 runs, 1 assertions, 0 failures, 0 errors, 0 skips")
  end

  def test_noisy_test_in_fail_on_output
    process = spawn_test_process(
      test_file: "noisy_tests.rb",
      arguments: ["--fail-on-output", "-n", "test_pass_with_noisy_stdout"],
      env: { "CI" => "yes" },
    ).value

    refute_test_process_successful(process)
    assert_test_process_output_includes(process, "The test unexpectedly wrote output to STDOUT or STDERR.")
    assert_test_process_output_includes(process, "STDOUT noise")
    assert_test_process_output_includes(process, "1 runs, 1 assertions, 1 failures, 0 errors, 0 skips")
  end

  def test_debugger_is_noop
    process = spawn_test_process(
      test_file: "test_with_debugger.rb",
      env: { "CI" => "yes" },
    ).value

    assert_test_process_successful(process)
  end

  private

  def normalize_output(string)
    string.gsub(/\d+\.\d+/, "0.012")
  end
end
