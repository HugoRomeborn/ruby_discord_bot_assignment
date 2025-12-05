class DiceCommand < Command
  def initialize
    super(name: "dice", description: "Slår en tärning")
  end

  def execute(event)
    event.respond("Du slog: " + rand(1..6).to_s)
  end
end