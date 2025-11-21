class InfoCommand
  attr_reader :name, :description
  def initialize
    @name = "info"
    @description  = "Informerar om bot"
  end

  def execute(event)
    event.respond("Jag är en bot som hjälper denna server att fungera.")
  end
end