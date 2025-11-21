class PingCommand
  attr_reader :name, :description
  def initialize()
    @name = "ping"
    @description = "svarar med pong"
  end

  def execute(event)
    event.respond("Pong!")
  end
end