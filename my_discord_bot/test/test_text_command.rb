require_relative 'spec_helper'
require_relative '../lib/text_command'

class TestTextCommand < Minitest::Test
  def test_text_command_can_be_created
    command = TextCommand.new(
      name: "test",
      description: "Test command",
      text: "Test response"
    )

    assert_instance_of TextCommand, command
    assert_kind_of Command, command  # Ärver från Command
    assert_equal "test", command.name
    assert_equal "Test command", command.description
  end

  def test_text_command_responds_with_text
    command = TextCommand.new(
      name: "greet",
      description: "Greets user",
      text: "Welcome!"
    )
    command_2 = TextCommand.new(
      name: "hello",
      description: "Says hello!",
      text: "Hello!"
    )
    mock_event = MockEvent.new
    mock_event_2 = MockEvent.new
    command.execute(mock_event)
    command_2.execute(mock_event_2)

    assert_equal 1, mock_event.responses.length
    assert_equal "Welcome!", mock_event.responses.first
    assert_equal 1, mock_event_2.responses.length
    assert_equal "Hello!", mock_event_2.responses.first
  end
end