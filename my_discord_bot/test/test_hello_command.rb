require_relative 'spec_helper'
require_relative '../lib/hello_command'

class TestHelloCommand < Minitest::Test
  def test_hello_command_has_name_and_description
    command = HelloCommand.new

    assert_equal "hello", command.name
    assert_equal "Säger hej!", command.description
  end

  def test_hello_command_responds_with_greeting
    command = HelloCommand.new
    mock_event = MockEvent.new(content: "!hello")

    command.execute(mock_event)

    # Kontrollera att bot:en svarade
    assert_equal 1, mock_event.responses.length
    assert_equal "Hello!", mock_event.responses.first
  end
end