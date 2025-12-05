class Command
  attr_reader :name, :description
  def initialize(name:, description: "no description")
    @name = name
    @description = description
  end

  def execute(event:)
    raise NotImplementedError, "Subclass must implement execute method"
  end
end