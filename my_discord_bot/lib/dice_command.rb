class DiceCommand
  attr_reader :name, :description
  def initialize
    @name = "dice"
    @description  = "Slår en tärning"
  end

  def execute(event)
    event.respond("Du slog: " + rand(1..6).to_s)
  end
end