class EchoCommand
  attr_reader :name, :description
  def initialize
    @name = "echo"
    @description = "Ger ett eko av användarens meddelande"
  end

  def execute(event)
    content = event.content
    content.delete_prefix!("!echo")
    event.respond("Echo: " + content)
  end
end