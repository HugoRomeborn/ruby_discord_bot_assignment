require_relative 'spec_helper'      # Laddar Minitest och mocks
require_relative '../lib/command'  # Klassen vi ska skapa (fortfarande explicit!)

class TestCommand < Minitest::Test
  def test_command_can_be_created
    # Skapa ett Command-objekt med name och description
    command = Command.new(name: "hello", description: "Says hello")

    # Verifiera att objektet skapades korrekt
    assert_instance_of Command, command
    assert_equal "hello", command.name
    assert_equal "Says hello", command.description
  end

  def test_command_has_execute_method
    command = Command.new(name: "test", description: "Test command")
    mock_event = MockEvent.new(content: "!test")

    assert_respond_to command, :execute
  end
end

