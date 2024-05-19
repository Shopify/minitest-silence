# frozen_string_literal: true

require "minitest/autorun"
require "byebug"

class TestWithDebugger < Minitest::Test
  def test_debugger
    debugger # rubocop:disable Lint/Debugger
    pass
  end
end
