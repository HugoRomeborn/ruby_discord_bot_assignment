require_relative 'spec_helper'
require_relative '../lib/info_command'

class TestHelloCommand < Minitest::Test
  def test_info_command_has_name_and_description
    command = InfoCommand.new

    assert_equal "info", command.name
    assert_equal "Informerar om bot", command.description
  end

  def test_hello_command_responds_with_greeting
    command = InfoCommand.new
    mock_event = MockEvent.new(content: "!info")

    command.execute(mock_event)

    # Kontrollera att bot:en svarade
    assert_equal 1, mock_event.responses.length
    assert_equal "Jag är en bot som hjälper denna server att fungera.", mock_event.responses.first
  end
end