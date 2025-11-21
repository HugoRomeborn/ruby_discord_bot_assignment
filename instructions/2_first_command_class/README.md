# Uppgift 2: First Command Class

## Översikt

Nu ska du bygga din första `Command` klass med TDD! Du kommer lära dig:
- Hur man testar kod som interagerar med externa system (Discord) genom att använda **mocks**
- Bygga en `Command` basklass med TDD
- Skapa `HelloCommand` och `PingCommand`
- Koppla ihop klasser med din Discord-bot

I slutet av denna uppgift kommer din bot ha en strukturerad kommandosystem med testade klasser.

## Förutsättningar

- ✅ Uppgift 1 klar (Discord bot setup)
- ✅ Din `my_discord_bot/` mapp från Uppgift 1

## Lärandemål

Efter denna uppgift ska du kunna:
- Förstå varför vi **mockar externa beroenden** i tester
- Skriva tester för kod som interagerar med externa API:er
- Bygga en `Command` klass med TDD
- Använda keyword arguments i konstruktorer
- Koppla klasser till Discord events

---

## Din Projektmapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp** som du skapade i Uppgift 1!

**Resten av instruktionerna förutsätter att du arbetar i din `my_discord_bot`-mapp.**

---

## Del 1: Koncept - Mocking External Dependencies

Innan vi börjar testa behöver vi förstå ett viktigt koncept: **mocking**.

#### Vad är Mocking?

**Mocking** betyder att ersätta ett riktigt objekt med en "fake" version i tester.

**Exempel:**
```ruby
# Riktigt objekt (pratar med Discord API)
real_event = discord_bot.message_event  # Gör API-anrop!

# Mock objekt (fake, för tester)
mock_event = MockEvent.new(content: "!hello")  # Inget API-anrop
```

#### Varför Behöver Vi Mocking?

**Problem utan mocks:**
```ruby
# ❌ Test som pratar med Discord API direkt
def test_bot_responds_to_hello
  bot = DiscordBot.new
  bot.start  # Startar bot, ansluter till internet
  # ... skicka meddelande via Discord...
  # ... vänta på svar...
  # ... kontrollera svar...
end
```

**Problem:**
- ❌ Kräver internetanslutning
- ❌ Långsamt (API-anrop tar tid)
- ❌ Kan nå Discord rate limits
- ❌ Svårt att testa edge cases (vad om Discord är nere?)
- ❌ Kan skicka riktiga meddelanden till Discord (spam!)

**Lösning med mocks:**
```ruby
# ✅ Test med mock (ingen internet, snabbt, säkert)
def test_command_responds_to_hello
  command = HelloCommand.new
  mock_event = MockEvent.new(content: "!hello")

  command.execute(mock_event)

  assert_equal "Hello!", mock_event.responses.first
end
```

**Fördelar:**
- ✅ Inga API-anrop (snabbt!)
- ✅ Fungerar offline
- ✅ Inga rate limits
- ✅ Lätt att testa edge cases
- ✅ Inget spam till Discord

#### Vad Ska Vi Mocka?

**Tumregel:**
- ✅ **Mocka:** Externa beroenden (Discord API, databaser, filsystem, nätverk)
- ❌ **Mocka INTE:** Din egen kod (klasser du skriver)

**Exempel:**
```ruby
# ✅ MOCKA Discord events
mock_event = MockEvent.new

# ❌ MOCKA INTE dina egna klasser
command = Command.new  # Riktigt objekt, inte mock!
```

---

### Förstå MockEvent - Vår Test Helper

Vi har skapat mock-klasser åt dig i `test/mock_event.rb`. Låt oss förstå hur de fungerar!

#### Vad är ett Discord Event?

Discord skickar "events" när saker händer (meddelanden, reactions, etc.). Ett message event har:
- `content` - meddelandets text (t.ex. "!hello")
- `user` - vem som skrev meddelandet
- `channel` - vilken kanal meddelandet skickades i
- `server` - vilken server kanalen tillhör
- `respond(message)` - metod för att skicka svar

#### MockEvent Klassen

Öppna `test/mock_event.rb` och titta på `MockEvent` klassen:

```ruby
class MockEvent
  attr_accessor :content, :responses
  attr_reader :user, :channel, :server

  def initialize(content: "", user: nil, channel: nil, server: nil)
    @content = content
    @user = user || MockUser.new
    @channel = channel || MockChannel.new
    @server = server || MockServer.new
    @responses = []  # Spara alla svar för verifiering i tester
  end

  def respond(message)
    @responses << message  # Spara svaret
    message
  end
end
```

**Vad gör den?**
- **Simulerar Discord events** - har samma struktur som riktiga Discord events
- **`responses` array** - sparar alla svar så vi kan testa dem!
- **Inget internet** - fungerar helt offline
- **Snabb** - inga API-anrop

#### Hur använder vi MockEvent?

**I dina tester:**
```ruby
# Skapa ett mock event
mock_event = MockEvent.new(content: "!hello")

# Kör din command
command.execute(mock_event)

# Kontrollera att command svarade rätt
assert_equal "Hello!", mock_event.responses.first
```

**Varför `responses` array?**

När din command anropar `event.respond("Hello!")`, sparas "Hello!" i `responses` arrayen. Detta låter oss verifiera att rätt meddelande skickades!

```ruby
# Utan responses array - hur vet vi vad som skickades?
event.respond("Hello!")  # Går förlorat...

# Med responses array - vi kan testa!
event.respond("Hello!")  # Sparas i responses
assert_equal "Hello!", event.responses.first  # Vi kan kontrollera!
```

#### MockUser, MockChannel, MockServer

Filen innehåller även `MockUser`, `MockChannel`, och `MockServer`:

```ruby
class MockUser
  attr_reader :name, :id
  def initialize(name: "TestUser", id: 123456789)
    @name = name
    @id = id
  end
end
```

**Varför behövs dessa?**

Senare kommer du bygga kommandon som använder information om användaren, kanalen, eller servern:

```ruby
# Kommando som använder username
mock_user = MockUser.new(name: "Alice", id: 999)
mock_event = MockEvent.new(content: "!greet", user: mock_user)

command.execute(mock_event)  # "Hello, Alice!"
```

**Just nu** behöver du bara förstå att dessa klasser finns. Vi använder dem mer i senare uppgifter.

**Kopiera `test`-mappen med `mock_event.rb` till ditt projekts rotmapp**

---

### Ruby Best Practice: Keyword Arguments

Innan vi börjar bygga vår `Command` klass behöver vi förstå **keyword arguments** - en Ruby best practice som gör koden mycket tydligare.

#### Vad är Keyword Arguments?

Keyword arguments låter dig namnge parametrar när du anropar metoder och konstruktorer.

**Exempel:**
```ruby
# ❌ Positionella argument - oklart vad varje värde betyder
command = Command.new("hello", "Says hello", true, 5)
# Vad betyder true? Vad betyder 5?

# ✅ Keyword arguments - kristallklart!
command = Command.new(
  name: "hello",
  description: "Says hello",
  enabled: true,
  cooldown: 5
)
```

#### Varför Använda Keyword Arguments?

1. **Läsbarhet** - Tydligt vad varje värde betyder
2. **Ordningen spelar ingen roll** - `name: "hello", description: "..."` fungerar lika bra som `description: "...", name: "hello"`
3. **Lättare att underhålla** - Kan lägga till nya parametrar utan att bryta existerande kod
4. **Färre buggar** - Svårt att blanda ihop ordningen på parametrar

#### Syntax

**Definiera metod med keyword arguments:**
```ruby
def initialize(name:, description:)
  @name = name
  @description = description
end
```

Notera kolonet **efter** parameternamnet: `name:`, `description:`

**Anropa metoden:**
```ruby
command = Command.new(name: "hello", description: "Says hello")
```

Notera kolonet **före** värdet: `name:`, `description:`

#### Obligatoriska vs Valfria Keyword Arguments

```ruby
# Obligatoriska (måste anges)
def initialize(name:, description:)
  # name och description MÅSTE anges när man skapar objektet
end

# Valfria (har default-värden)
def initialize(name:, description: "No description")
  # description är valfri, default är "No description"
end
```

#### Din Uppgift

**Använd keyword arguments i alla dina konstruktorer!** Detta kommer göra din kod tydligare och är Ruby best practice.

---

## Del 2: Bygg Command Klasser med TDD

Nu ska vi bygga våra första klasser med TDD! Vi börjar med en bas-`Command` klass, sedan `HelloCommand` och `PingCommand`.

### Skapa spec_helper.rb

Innan vi skriver tester ska vi skapa `spec_helper.rb` - en fil som konfigurerar vår testmiljö.

**Varför spec_helper?**
- Slipper upprepa `require 'minitest/autorun'` i varje testfil
- Centraliserar testkonfiguration (som minitest-reporters)
- Laddar gemensamma test-hjälpare (mocks)

**Din uppgift:** Skapa `test/spec_helper.rb`:

```ruby
require 'minitest/autorun'
require 'minitest/reporters'

# Aktivera SpecReporter för färgglad output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Ladda test-hjälpare (mocks)
require_relative 'mock_event'
```

**Vad gör den?**
- Laddar Minitest
- Aktiverar minitest-reporters (från Assignment 1) för snygg output
- Laddar mock_event.rb så alla tester kan använda MockEvent

**Notera:** Vi laddar INTE `../lib/*` filer här! Varje test ska fortfarande explicit `require_relative` sin produktionskod. Detta håller dependencies tydliga.

---

### Test 1: Command kan skapas

#### 🔴 RED - Skriv testet

Vi börjar med att skapa en bas-`Command` klass. Denna kommer vara en generisk klass som kan representera vilket kommando som helst.

Skapa `test/test_command.rb`:

```ruby
require_relative 'spec_helper'      # Laddar Minitest och mocks
require_relative '../lib/command'  # Klassen vi ska skapa (fortfarande explicit!)

class TestCommand < Minitest::Test
  def test_command_can_be_created
    # Skapa ett Command-objekt med name och description
    command = Command.new(name: "hello", description: "Says hello")

    # Verifiera att objektet skapades korrekt
    assert_instance_of Command, command
    assert_equal "hello", command.name
    assert_equal "Says hello", command.description
  end
end
```

**Kör testet:**
```bash
ruby test/test_command.rb
```

Det ska misslyckas: `cannot load such file -- command`

#### 🟢 GREEN - Implementera Command

**Din uppgift:** Skapa `lib/command.rb` med en `Command` klass.

**Vad behöver den?**
- Constructor som tar `name:` och `description:` (keyword arguments)
- Spara dessa i instansvariabler
- `attr_reader` för att komma åt dem

**Kör testet** - det ska passera!

---

### Test 2: Command kan exekveras

#### 🔴 RED - Skriv testet

En command ska ha en `execute` metod som tar ett event och gör något.

**Din uppgift:** Lägg till detta test i `test/test_command.rb`:

```ruby
def test_command_has_execute_method
  command = Command.new(name: "test", description: "Test command")
  mock_event = MockEvent.new(content: "!test")

  # execute metoden ska finnas (även om den inte gör något än)
  assert_respond_to command, :execute
end
```

**Kör testet** - det ska misslyckas: `undefined method 'execute'`

#### 🟢 GREEN - Implementera execute

**Din uppgift:** Lägg till en `execute` metod i `Command` klassen.

```ruby
def execute(event)
  # Bas-implementation - subklasser kommer override:a denna
  nil
end
```

**Kör testet** - det ska passera!

---

### Test 3: Skapa en HelloCommand

Nu har vi bas-klassen! Låt oss skapa ett riktigt kommando.

#### 🔴 RED - Skriv testet

Skapa `test/test_hello_command.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/hello_command'

class TestHelloCommand < Minitest::Test
  def test_hello_command_has_name_and_description
    command = HelloCommand.new

    assert_equal "hello", command.name
    assert_equal "Säger hej!", command.description
  end

  def test_hello_command_responds_with_greeting
    command = HelloCommand.new
    mock_event = MockEvent.new(content: "!hello")

    command.execute(mock_event)

    # Kontrollera att bot:en svarade
    assert_equal 1, mock_event.responses.length
    assert_equal "Hello!", mock_event.responses.first
  end
end
```

**Kör testet** - det ska misslyckas: `cannot load such file -- hello_command`

#### 🟢 GREEN - Implementera HelloCommand

**Din uppgift:** Skapa `lib/hello_command.rb`

**Vad behöver den?**
- Constructor som inte tar några argument (name och description är hårdkodade)
- Instansvariabler `@name` och `@description`
- `attr_reader för att komma åt Instansvariablerna
- `execute(event)` metod som anropar `event.respond("Hello!")`

**Kör testerna** - de ska passera!

---

### Test 4: Skapa en PingCommand

#### 🔴 RED - Skriv tester

**Din uppgift:** Skapa `test/test_ping_command.rb` och skriv tester för ett `PingCommand`.

**Vad ska PingCommand göra?**
- Svara med "Pong!" när någon skriver `!ping`

**Tester du behöver:**
1. Test att kommandot svarar med rätt meddelande
2. Test att kommandot har rätt namn och beskrivning

**Kör testerna** - de ska misslyckas

#### 🟢 GREEN - Implementera PingCommand

**Din uppgift:** Skapa `lib/ping_command.rb`

Följ samma mönster som `HelloCommand`.

**Kör testerna** - de ska passera!

---

## Del 3: Koppla Ihop Bot med Commands

Nu har vi kommandon som fungerar i tester! Dags att ansluta dem till Discord.

### Skapa Bot Runner

Skapa `bot.rb` i projektets root:

```ruby
require 'discordrb'
require 'dotenv/load'
require_relative 'lib/hello_command'
require_relative 'lib/ping_command'

# Hämta token från miljövariabel
token = ENV['DISCORD_BOT_TOKEN']

if token.nil? || token.empty?
  puts "❌ DISCORD_BOT_TOKEN är inte satt!"
  puts "Skapa en .env fil med: DISCORD_BOT_TOKEN=din_token"
  exit 1
end

# Skapa bot
bot = Discordrb::Bot.new(token: token)

# Skapa kommando-instanser
hello_command = HelloCommand.new
ping_command = PingCommand.new

# Hantera meddelanden
bot.message do |event|
  # Ignorera bot:ens egna meddelanden
  next if event.user.bot_account?

  content = event.content.strip.downcase

  # Kolla om meddelandet är ett kommando
  case content
  when "!hello"
    hello_command.execute(event)
  when "!ping"
    ping_command.execute(event)
  end
end

# Logga när bot:en startar
bot.ready do
  puts "✅ Bot inloggad som: #{bot.profile.username}"
  puts "📡 Bot är online och lyssnar på kommandon!"
  puts "💬 Testa: !hello eller !ping"
end

# Starta bot:en
puts "🚀 Startar bot..."
bot.run
```

### Kör Din Bot!

```bash
ruby bot.rb
```

Du ska se:
```
🚀 Startar bot...
✅ Bot inloggad som: MinRubyBot
📡 Bot är online och lyssnar på kommandon!
💬 Testa: !hello eller !ping
```

**Gå till Discord** och skriv `!hello` eller `!ping` i en kanal där bot:en finns!

Bot:en ska svara! 🎉

**Stoppa bot:en:** Tryck `Ctrl+C`

---

## Del 4: Lägg Till Fler Kommandon

### Feature: InfoCommand

**Din uppgift:** Skapa ett `!info` kommando som visar information om bot:en.

#### TDD-Process:

1. 🔴 **Skriv tester** i `test/test_info_command.rb`
   - Test att kommandot svarar med bot-information
   - Test att svaret innehåller bot:ens namn och beskrivning

2. 🟢 **Implementera** `lib/info_command.rb`
   - Svara med t.ex: "MinRubyBot v1.0 - En bot byggd med Ruby och TDD!"

3. 🔵 **Koppla in** kommandot i `bot.rb`
   - Lägg till `when "!info"`

**Kör tester** - de ska passera!

**Kör bot** - testa i Discord!

---

### Feature: DiceCommand (Valfritt)

**Din uppgift:** Skapa ett `!dice` kommando som rullar en tärning (1-6).

#### TDD-Process:

1. 🔴 **Skriv tester** i `test/test_dice_command.rb`
   - Test att kommandot returnerar ett nummer mellan 1 och 6
   - Test att resultatet är ett heltal
   - **Tips:** Kör testet flera gånger för att verifiera slumpmässighet

   **Testutmaning:** Hur testar man slumpmässighet?
   ```ruby
   def test_dice_returns_number_between_1_and_6
     command = DiceCommand.new

     # Kör 100 gånger för att verifiera range
     100.times do
       mock_event = MockEvent.new(content: "!dice")
       command.execute(mock_event)

       # Extrahera nummer från svaret (t.ex. "Du rullade: 4")
       response = mock_event.responses.first
       number = response.match(/\d+/)[0].to_i

       assert_includes 1..6, number
     end
   end
   ```

2. 🟢 **Implementera** `lib/dice_command.rb`
   - Använd `rand(1..6)` för att generera slumptal
   - Svara med t.ex: "Du rullade: 4"

3. 🔵 **Koppla in** kommandot i `bot.rb`

---

## Vanliga Misstag

### 1. Hårdkoda token i kod

```ruby
#Här skulle det stå kod som visar en token i din källkod, men det tillåter inte GitHub.
```

---

### 3. Testa för mycket i ett test

```ruby
# ❌ FEL - Testar flera saker
def test_everything
  command = HelloCommand.new
  assert_equal "hello", command.name
  assert_equal "Says hello", command.description
  mock_event = MockEvent.new
  command.execute(mock_event)
  assert_equal "Hello!", mock_event.responses.first
end

# ✅ RÄTT - Ett test per beteende
def test_command_has_correct_name
  command = HelloCommand.new
  assert_equal "hello", command.name
end

def test_command_responds_correctly
  command = HelloCommand.new
  mock_event = MockEvent.new
  command.execute(mock_event)
  assert_equal "Hello!", mock_event.responses.first
end
```

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Varför mockar vi Discord events i tester?**
   - Svar: För att tester ska vara snabba, pålitliga, och inte kräva internet/Discord API

2. **Varför använder vi `.env` fil för token?**
   - Svar: För att inte commit:a känslig information till Git

3. **Hur vet vi att våra kommandon fungerar?**
   - Svar: Tester verifierar logiken, sedan testar vi manuellt i Discord

---

## Stretch Goals (**Valfritt**)

### 1. EchoCommand

Skapa ett kommando som ekar tillbaka användarens meddelande.

**Exempel:**
- User: `!echo Hello world`
- Bot: `Echo: Hello world`

**Utmaning:** Hur hanterar du text efter `!echo`?

**Tips:**
```ruby
content = event.content  # "!echo Hello world"
text = content.sub("!echo", "").strip  # "Hello world"
```

---

### 2. UserInfoCommand

Skapa ett kommando som visar information om användaren.

**Exempel:**
- User: `!userinfo`
- Bot: `👤 Användarnamn: TestUser (ID: 123456789)`

**Tips:** Använd `event.user.name` och `event.user.id`

**Testutmaning:** Hur testar du att rätt användarnamn visas?
```ruby
def test_userinfo_shows_username
  mock_user = MockUser.new(name: "Alice", id: 999)
  mock_event = MockEvent.new(content: "!userinfo", user: mock_user)

  command = UserInfoCommand.new
  command.execute(mock_event)

  response = mock_event.responses.first
  assert_includes response, "Alice"
  assert_includes response, "999"
end
```

---

### 3. Command med argument

Skapa ett `!say <text>` kommando som får bot:en att säga något.

**Exempel:**
- User: `!say Ruby är coolt!`
- Bot: `Ruby är coolt!`

**TDD-Process:**
- Testa att kommandot extraherar rätt text
- Testa edge cases (tom text, bara `!say`)

---

### 4. Case-insensitive kommandon

Gör så att `!HELLO`, `!Hello`, och `!hello` alla fungerar.

**Var ska denna logik finnas?**
- I `bot.rb`? (där vi matchar kommandon)
- I varje Command klass?

**Diskussion:** Vilken lösning är bäst? Varför?

---

## Nästa Steg

I **Assignment 2** kommer vi lära oss:
- **Inheritance** - `HelloCommand` ärver från `Command`
- **Polymorphism** - Olika kommandotyper med gemensamt interface
- **Method overriding** - Subklasser override:ar `execute`
- Bygga `TextCommand`, `EmbedCommand`, `RandomCommand`

Men först: **Grattis!** Du har byggt din första Discord-bot med TDD! 🎉

## Resurser

- [discordrb Documentation](https://www.rubydoc.info/gems/discordrb)
- [discordrb GitHub Examples](https://github.com/shardlab/discordrb/tree/master/examples)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Bot Best Practices](https://discord.com/developers/docs/topics/community-resources#bots-and-apps)
- [dotenv gem documentation](https://github.com/bkeepers/dotenv)
- [Test Doubles (Mocks) Explanation](https://martinfowler.com/bliki/TestDouble.html)
