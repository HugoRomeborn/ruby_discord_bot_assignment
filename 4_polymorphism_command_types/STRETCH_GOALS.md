# Stretch Goals - Uppgift 4: Polymorphism & Command Types

Dessa är **valfria** utmaningar för dig som vill öva mer på polymorfism, argument parsing och Discord features.

---

## 1. EmbedCommand - Discord Embeds

Discord har **embeds** - rika meddelanden med färger, titlar, fält, bilder, etc. Detta är ett kraftfullt sätt att visa strukturerad information!

### Vad är Discord Embeds?

Embeds är rika meddelanden med snygg formatering. Tänk dig ett kort med färgad kant, titel, beskrivning och strukturerade fält.

I Discord renderas embeds som snygga kort med färger, ikoner och struktur!

### discordrb Embed Syntax

```ruby
event.channel.send_embed do |embed|
  embed.title = "Bot Information"
  embed.description = "This is a Ruby Discord bot"
  embed.color = 0x00ff00  # Grön färg (hex)
  embed.add_field(name: "Version", value: "1.0")
end
```

### Test 1: EmbedCommand Kan Skapas

#### 🔴 RED - Skriv Testet

Skapa `test/test_embed_command.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/embed_command'
require_relative '../lib/command'

class TestEmbedCommand < Minitest::Test
  def test_embed_command_can_be_created
    command = EmbedCommand.new(
      name: "info",
      description: "Shows bot info",
      title: "Bot Info",
      embed_description: "A cool bot",
      color: 0x00ff00
    )

    assert_instance_of EmbedCommand, command
    assert_kind_of Command, command
    assert_equal "info", command.name
    assert_equal "Bot Info", command.title
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera EmbedCommand

**Din uppgift:** Skapa `lib/embed_command.rb`

**Vad behöver den?**
- Ärv från `Command`
- Constructor som tar:
  - `name:` och `description:` (för Command)
  - `title:` (embed titel)
  - `embed_description:` (embed beskrivning)
  - `color:` (hex färgkod, t.ex. 0x00ff00)
- Anropa `super` med name och description
- Spara embed-specifika parametrar i instansvariabler
- `attr_reader` för title, embed_description, color
- `execute(event)` metod som anropar `event.channel.send_embed` med block

**Tips för execute:**
```ruby
def execute(event)
  event.channel.send_embed do |embed|
    embed.title = @title
    embed.description = @embed_description
    embed.color = @color
  end
end
```

**Kör testet** - det ska passa!

---

### Test 2: EmbedCommand Skickar Embed

För att testa embeds behöver vi uppdatera våra mock-klasser.

#### Uppdatera MockEvent

**Öppna `test/mock_event.rb` och uppdatera `MockChannel`:**

```ruby
class MockChannel
  attr_reader :name, :id
  attr_accessor :messages, :embeds

  def initialize(name: "test-channel", id: 987654321)
    @name = name
    @id = id
    @messages = []
    @embeds = []  # Ny! Spara embeds
  end

  def send_message(message)
    @messages << message
    message
  end

  def send_embed(&block)
    embed = MockEmbed.new
    block.call(embed)
    @embeds << embed  # Spara embed för verifiering
    embed
  end
end

# Ny mock klass för embeds
class MockEmbed
  attr_accessor :title, :description, :color, :fields

  def initialize
    @fields = []
  end

  def add_field(name:, value:, inline: false)
    @fields << { name: name, value: value, inline: inline }
  end
end
```

#### 🔴 RED - Skriv Testet

**Lägg till i `test/test_embed_command.rb`:**

```ruby
def test_embed_command_sends_embed
  command = EmbedCommand.new(
    name: "info",
    description: "Shows info",
    title: "Bot Information",
    embed_description: "A cool Ruby bot",
    color: 0x00ff00
  )
  mock_event = MockEvent.new

  command.execute(mock_event)

  # Verifiera att ett embed skickades
  assert_equal 1, mock_event.channel.embeds.length

  # Verifiera embed-innehåll
  embed = mock_event.channel.embeds.first
  assert_equal "Bot Information", embed.title
  assert_equal "A cool Ruby bot", embed.description
  assert_equal 0x00ff00, embed.color
end
```

**Kör testet** - det ska passa om din implementation är korrekt!

### Testa i Discord

Lägg till i `bot.rb`:

```ruby
require_relative 'lib/embed_command'

# Skapa ett embed-kommando
embed_info = EmbedCommand.new(
  name: "botinfo",
  description: "Shows bot info as embed",
  title: "🤖 Bot Information",
  embed_description: "A Discord bot built with Ruby and TDD!",
  color: 0x00ff00
)

# I message handler, lägg till:
when "!botinfo"
  embed_info.execute(event)
```

Testa `!botinfo` i Discord - du ska se ett snyggt embed!

---

## 2. EmbedCommand med Fields

Utöka `EmbedCommand` för att stödja fields (strukturerade fält i embeds).

**Exempel:**
```ruby
embed_command = EmbedCommand.new(
  name: "serverinfo",
  description: "Server info",
  title: "Server Information",
  embed_description: "Info about this server",
  color: 0x0099ff,
  fields: [
    { name: "Members", value: "42" },
    { name: "Created", value: "2024-01-01" }
  ]
)
```

**TDD-Process:**

1. 🔴 **Skriv test** - Test att fields läggs till korrekt
2. 🟢 **Implementera**:
   - Uppdatera constructor: `fields: []` (default tom array)
   - I `execute`, loopa: `@fields.each { |field| embed.add_field(name: field[:name], value: field[:value]) }`
3. 🔵 **Testa i Discord**

---

## 3. CoinFlip Command

Skapa ett `!flip` kommando som slår mynt.

**Exempel:**
- User: `!flip`
- Bot: `🪙 Du fick: Krona!` (eller `Klave!`)

**TDD-Process:**

```ruby
def test_coinflip_returns_both_outcomes
  command = CoinFlipCommand.new
  results = []

  # Kör 100 gånger
  100.times do
    mock_event = MockEvent.new
    command.execute(mock_event)
    results << mock_event.responses.first
  end

  # Verifiera att båda "Krona" och "Klave" dyker upp
  assert results.any? { |r| r.include?("Krona") }
  assert results.any? { |r| r.include?("Klave") }
end
```

**Implementera:** Använd `["Krona", "Klave"].sample`

---

## 4. RollCommand med Multiple Dice Types

Utöka RollCommand för att hantera `!roll 1d20+2d6`.

**Exempel:**
- User: `!roll 1d20+2d6`
- Bot: `🎲 1d20: 15 | 2d6: 3, 4 = Total: 22`

**Tips:**
```ruby
notation = "1d20+2d6"
parts = notation.split('+')  # ["1d20", "2d6"]

# Parsa varje del separat
parts.each do |part|
  match = part.match(/^(\d+)?d(\d+)$/i)
  # ... rulla och spara resultat
end
```

---

## 5. Command Registry

Skapa en `CommandRegistry` klass som håller alla kommandon dynamiskt.

**Konceptet:**
```ruby
registry = CommandRegistry.new
registry.register(hello_command)
registry.register(ping_command)

# I message handler
command = registry.find("!hello")
command.execute(event) if command
```

**Fördelar:**
- Slipper case statement
- Lätt att lista alla kommandon (förberedelse för !help)
- Förberedelse för Uppgift 5!

**TDD-Process:**

```ruby
def test_registry_can_register_and_find_commands
  registry = CommandRegistry.new
  command = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  
  registry.register(command)
  found = registry.find("!hello")
  
  assert_equal command, found
end
```

**Implementera:**
```ruby
class CommandRegistry
  def initialize
    @commands = {}
  end

  def register(command)
    @commands["!#{command.name}"] = command
  end

  def find(command_name)
    @commands[command_name]
  end

  def all
    @commands.values
  end
end
```

---

## 6. QuoteCommand med Random Selection

Skapa ett `!quote` kommando som returnerar slumpmässiga citat.

**Exempel:**
- User: `!quote`
- Bot: `"The only way to do great work is to love what you do." - Steve Jobs`

**Implementera:**
```ruby
class QuoteCommand < Command
  def initialize(quotes:)
    super(name: "quote", description: "Random quote")
    @quotes = quotes
  end

  def execute(event)
    event.respond(@quotes.sample)
  end
end
```

**Testutmaning:** Kör 100 gånger och verifiera att alla citat visas minst en gång!

---

## 7. MathCommand med Argument Parsing

Skapa ett `!math` kommando för enkel matematik.

**Exempel:**
- User: `!math 5 + 3`
- Bot: `🔢 Resultat: 8`

**Utmaningar:**
- Parsa flera argument: `args = ["5", "+", "3"]`
- Validera operation (+, -, *, /)
- Hantera edge cases (division med 0)

**Säkerhetsvarning:** Använd **INTE** `eval()` - det är osäkert! Parsa manuellt:

```ruby
def execute(event, args = [])
  return event.respond("Usage: !math <num1> <op> <num2>") if args.length != 3
  
  num1 = args[0].to_f
  op = args[1]
  num2 = args[2].to_f
  
  result = case op
  when "+" then num1 + num2
  when "-" then num1 - num2
  when "*" then num1 * num2
  when "/" then num2 == 0 ? "Division by zero!" : num1 / num2
  else "Invalid operation!"
  end
  
  event.respond("🔢 Resultat: #{result}")
end
```

---

## Vilka Stretch Goals Tränar Vad?

- **EmbedCommand** - Ruby blocks, Discord API features, structured data
- **EmbedCommand med Fields** - Arrays, hashes, iteration
- **CoinFlipCommand** - Boolean randomness, comprehensive testing
- **RollCommand Multiple Dice** - Advanced string parsing, complex iteration
- **Command Registry** - Encapsulation, dynamic lookup (försmak av Uppgift 5!)
- **QuoteCommand** - Arrays, random selection, testing randomness
- **MathCommand** - Argument parsing, validation, error handling, security

Lycka till! 🎉
