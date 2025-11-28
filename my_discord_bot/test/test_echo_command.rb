require_relative 'spec_helper'
require_relative '../lib/echo_command'

class TestEchoCommand < Minitest::Test
  def test_echo_command_has_name_and_description
    command = EchoCommand.new

    assert_equal "echo", command.name
    assert_equal "Ger ett eko av användarens meddelande", command.description
  end

  def test_echo_returns_correct_string
    command = EchoCommand.new
    messages = [" hello world", "what", " ho ho ho", " !echo", " hello    World \nhello word"]
    messages.each do |message|
      mock_event = MockEvent.new(content: "!echo" + message)
      command.execute(mock_event)

    
      correct = "Echo: " + message

      assert_includes correct, mock_event.responses.first
    end
  end
end