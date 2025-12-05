require_relative 'spec_helper'
require_relative '../lib/dice_command'

class TestDiceCommand < Minitest::Test
  def test_dice_command_has_name_and_description
    command = DiceCommand.new

    assert_equal "dice", command.name
    assert_equal "Slår en tärning", command.description
  end

  def test_dice_returns_number_between_1_and_6
    command = DiceCommand.new

    # Kör 100 gånger för att verifiera range
    100.times do
      mock_event = MockEvent.new(content: "!dice")
      command.execute(mock_event)

      # Extrahera nummer från svaret (t.ex. "Du rullade: 4")
      response = mock_event.responses.first
      number = response.match(/\d+/)[0].to_i

      assert_includes 1..6, number
    end
  end

  def test_dice_command_is_a_command
    command = DiceCommand.new
    assert_instance_of DiceCommand, command
    assert_kind_of Command, command
  end
end