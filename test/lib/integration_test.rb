# typed: true
# frozen_string_literal: true

class IntegrationTest < Minitest::Test
  TEST_FILE_FIXTURES = File.expand_path('../../fixtures/', __FILE__)

  class TestProcessResult < Struct.new(:status, :stdout)
  end

  def spawn_test_process(
    test_file:,
    arguments: {},
    timeout: 10,
    env: {}
  )
    Thread.new do
      Thread.current.report_on_exception = false

      stdout_reader, stdout_writer = IO.pipe
      stdout_thread = Thread.new { stdout_reader.read }

      status = nil
      begin
        pid = Process.spawn(
          env,
          RbConfig.ruby,
          File.join(TEST_FILE_FIXTURES, test_file),
          *arguments.flat_map(&:itself),
          out: stdout_writer,
        )

        killer = Thread.new do
          sleep(timeout)
          Process.kill('KILL', pid)
          STDERR.puts("Sent kill signal to test process after #{timeout}s...")
        rescue Errno::ESRCH
          # spawned process exited normally
        end

        begin
          _, status = Process.waitpid2(pid)
        ensure
          killer.kill
        end
      ensure
        stdout_writer.close
      end

      TestProcessResult.new(status, stdout_thread.value)
    end
  end

  def assert_test_process_output_includes(process, expected_output)
    if process.stdout.include?(expected_output)
      pass
    else
      flunk <<~EOM
        Expected the output of the process to include #{expected_output.inspect}.
        #{Minitest::Silence.boxed(process_header(process), process.stdout)}
      EOM
    end
  end

  def refute_test_process_output_includes(process, expected_output)
    if process.stdout.include?(expected_output)
      flunk <<~EOM
        Expected the output of the process to not include #{expected_output.inspect}.
        #{Minitest::Silence.boxed(process_header(process), process.stdout)}
      EOM
    else
      pass
    end
  end

  def process_header(process)
    result = if (exitstatus = process.status.exitstatus)
      "exited with #{exitstatus}"
    elsif (termsig = process.status.termsig)
      "signaled with #{Signal.signame(termsig)}"
    else
      raise "Unexpected process status: #{process.status.inspect}"
    end
    "Test process output (#{result})"
  end

  def refute_test_process_successful(process)
    if process.status.exitstatus == 1
      pass
    else
      flunk <<~EOM
        The test process was unexpectedly successful.
        #{Minitest::Silence.boxed(test_process_header(process), process.stdout)}
      EOM
    end
  end

  def assert_test_process_successful(process)
    if process.status.exitstatus == 0
      pass
    else
      flunk <<~EOM
        The test process unexpectedly was not successul.
        #{Minitest::Silence.boxed(process_header(process), process.stdout)}
      EOM
    end
  end
end
