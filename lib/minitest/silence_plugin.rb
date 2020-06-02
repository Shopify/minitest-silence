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
        $stdout.reopen(output_writer)
        $stderr.reopen(output_writer)

        result = begin
          super
        ensure
          output_writer.close
          $stdout.reopen(old_stdout)
          $stderr.reopen(old_stderr)
        end

        result.output = output_thread.value
        result
      end
    end

    class << self
      def console_width
        @console_width ||= IO.console.winsize.fetch(1)
      end

      def boxed(title, content, line_width: console_width)
        box = +"┌── #{title} #{'─' * (line_width - title.length - 6)}┐\n"
        box << content.gsub(/(.{#{line_width - 4}}|.*\n)/) do |line|
          format("│ %-#{line_width - 4}s |\n", line.chomp)
        end
        box << "└#{'─' * (line_width - 2)}┘\n"
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
    end
  end
end
