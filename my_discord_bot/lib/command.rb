class Command
  attr_reader :name, :description
  def initialize(name:, description: "no description")
    @name = name
    @description = description
  end

  def execute(event:)
    nil
  end
end