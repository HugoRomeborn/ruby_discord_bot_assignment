require_relative 'spec_helper'
require_relative '../lib/roll_command'

class TestRollCommand < Minitest::Test
  def test_roll_command_can_be_created
    command = RollCommand.new

    assert_instance_of RollCommand, command
    assert_kind_of Command, command
    assert_equal "roll", command.name
    assert_equal "Roll dice (e.g. !roll d20, !roll 2d6)", command.description
  end
end