# MockEvent - Simulerar Discord events för tester
#
# Varför mocka?
# - Tester blir snabba (inga API-anrop)
# - Fungerar offline
# - Kan inte spamma Discord
# - Kan testa edge cases enkelt
#
# Användning:
#   mock_event = MockEvent.new(content: "!hello")
#   command.execute(mock_event)
#   assert_equal "Hello!", mock_event.responses.first
#
# Vad är ett Discord Event?
# Discord skickar "events" när saker händer (meddelanden, reactions, etc.).
# Ett message event har:
# - content: meddelandets text (t.ex. "!hello")
# - user: vem som skrev meddelandet
# - channel: vilken kanal meddelandet skickades i
# - server: vilken server kanalen tillhör
# - respond(message): metod för att skicka svar
#
class MockEvent
  attr_accessor :content, :responses
  attr_reader :user, :channel, :server

  def initialize(content: "", user: nil, channel: nil, server: nil)
    @content = content
    @user = user || MockUser.new
    @channel = channel || MockChannel.new
    @server = server || MockServer.new
    @responses = []  # Spara alla svar så vi kan verifiera dem i tester
  end

  # Simulera Discord's respond metod
  # Istället för att skicka till Discord, sparar vi i @responses array
  def respond(message)
    @responses << message
    message
  end
end

# MockUser - Simulerar Discord användare
#
# Användning (framtida uppgifter):
#   mock_user = MockUser.new(name: "Alice", id: 999)
#   mock_event = MockEvent.new(content: "!greet", user: mock_user)
#   command.execute(mock_event)  # Kan använda event.user.name i kommandot
#
class MockUser
  attr_reader :name, :id

  def initialize(name: "TestUser", id: 123456789)
    @name = name
    @id = id
  end
end

# MockChannel - Simulerar Discord kanal
#
# Används när kommandon behöver skicka meddelanden direkt till kanalen
# istället för att svara på ett event.
#
class MockChannel
  attr_reader :name, :id
  attr_accessor :messages

  def initialize(name: "test-channel", id: 987654321)
    @name = name
    @id = id
    @messages = []
  end

  def send_message(message)
    @messages << message
    message
  end
end

# MockServer - Simulerar Discord server
#
# Används när kommandon behöver serverinformation.
#
class MockServer
  attr_reader :name, :id

  def initialize(name: "Test Server", id: 111222333)
    @name = name
    @id = id
  end
end
