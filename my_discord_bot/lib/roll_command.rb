class RollCommand < Command
  def initialize()
    super(name: "roll", description: "Roll dice (e.g. !roll d20, !roll 2d6)")
  end

  def execute(event, args="")
    if args == ""
      roll_results = rand(1..6)
      event.respond("🎲 Rullade 1d6: = **#{results}**")
    elsif
      args.split("d")
      if args[0] == ""

      event.respond("🎲 Rullade #{count}d#{sides}: #{results.join(', ')} = **#{total}**")
    end

  end
end