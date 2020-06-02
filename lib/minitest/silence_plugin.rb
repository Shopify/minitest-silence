# frozen_string_literal: true

require "minitest/silence/fail_on_output_reporter"
require "minitest/silence/boxed_output_reporter"
require "minitest/silence/version"
require "io/console"

module Minitest
  module Silence
    Error = Class.new(StandardError)
    UnexpectedOutput = Class.new(Error)

    module ResultOutputPatch
      attr_accessor :output
    end

    module RunOneMethodPatch
      def run_one_method(klass, method_name)
        output_reader, output_writer = IO.pipe
        output_thread = Thread.new { output_reader.read }

        old_stdout = $stdout.dup
        old_stderr = $stderr.dup

        result = begin
          $stdout.reopen(output_writer)
          $stderr.reopen(output_writer)
          super
        ensure
          $stdout.reopen(old_stdout)
          $stderr.reopen(old_stderr)
          output_writer.close
        end

        result.output = output_thread.value
        result
      end
    end

    class << self
      DEFAULT_CONSOLE_WIDTH = 80

      def setup_winsize_trap
        Signal.trap('WINCH') do
          @console_width = nil
        end
      end

      def console_width
        @console_width ||= if IO.console
          IO.console.winsize.fetch(1)
        else
          DEFAULT_CONSOLE_WIDTH
        end
      end

      def boxed(title, content, line_width: console_width)
        box = +"── #{title} ──\n"
        box << "#{content}\n"
        box << "───#{'─' * title.length}───\n"
      end
    end
  end

  class << self
    def plugin_silence_options(opts, options)
      opts.on('--fail-on-output', "Fail a test when it writes to STDOUT or STDERR") do
        options[:fail_on_output] = true
      end
    end

    def plugin_silence_init(options)
      Minitest::Result.prepend(Minitest::Silence::ResultOutputPatch)
      Minitest.singleton_class.prepend(Minitest::Silence::RunOneMethodPatch)

      if options[:fail_on_output]
        # We have to make sure this reporter runs as the first reporter, so it can still adjust
        # the result and other reporters will take the change into account.
        reporter.reporters.unshift(Minitest::Silence::FailOnOutputReporter.new(options[:io], options))
      elsif options[:verbose]
        reporter << Minitest::Silence::BoxedOutputReporter.new(options[:io], options)
      end

      Minitest::Silence.setup_winsize_trap
    end
  end
end
