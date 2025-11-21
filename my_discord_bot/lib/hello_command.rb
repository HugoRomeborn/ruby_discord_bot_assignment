class HelloCommand
  attr_reader :name, :description
  def initialize()
    @name = "hello"
    @description = "Säger hej!"
  end

  def execute(event)
    event.respond("Hello!")
  end
end