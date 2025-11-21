require_relative 'spec_helper'
require_relative '../lib/ping_command'

class TestPingCommand < Minitest::Test
  def test_ping_command_has_name_and_descriprion
    command = PingCommand.new
    assert_equal "ping", command.name
    assert_equal "svarar med pong", command.description
  end

  def test_ping_command_responds_with_pong
    command = PingCommand.new
    mock_event = MockEvent.new(content: "!ping")

    command.execute(mock_event)

    assert_equal 1, mock_event.responses.length
    assert_equal "Pong!", mock_event.responses.first
  end

end