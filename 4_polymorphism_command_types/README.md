# Uppgift 4: Polymorphism & Command Types

## Översikt

I denna uppgift ska du tillämpa arv för att skapa **polymorfiska command types**: TextCommand (generisk text) och RollCommand (tärningsrullning med arguments).

## Förutsättningar

- ✅ Uppgift 3 klar (Inheritance Basics)

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förstå **polymorfism** i praktiken
- Skapa generiska klasser med arv
- Parsa och validera command arguments
- Använda samma interface för olika beteenden

---

## Koncept: Polymorfism

**Polymorfism** betyder att olika klasser kan ha samma interface (metoder) men olika implementation.

**Från Uppgift 3:** `HelloCommand` och `PingCommand` ärver från `Command` - de kan behandlas likadant trots olika beteenden.

**I denna uppgift:** Vi skapar **generiska** kommandotyper som kan konfigureras:

```ruby
# Istället för många dedikerade klasser:
hello = HelloCommand.new  # Hårdkodat
bye = ByeCommand.new      # Hårdkodat

# Använd EN konfigurerbar klass:
hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
bye = TextCommand.new(name: "bye", description: "Says bye", text: "Goodbye!")
```

**Polymorfism i praktiken:**
```ruby
commands = [
  TextCommand.new(name: "hello", ...),
  TextCommand.new(name: "ping", ...),
  RollCommand.new
]

# Alla har samma interface (execute), olika beteende
commands.each { |cmd| cmd.execute(event) }
```

**Varför är detta kraftfullt?**
- Vi kan behandla olika kommandotyper på samma sätt
- Lätt att lägga till nya kommandotyper
- Kod som använder kommandon behöver inte veta vilken specifik typ det är

---

## Del 1: Skapa TextCommand

Nu ska vi skapa en **generisk** `TextCommand` klass som kan användas för enkla textmeddelanden.

### Konceptet

Istället för att skapa en ny klass för varje enkelt textkommando kan vi skapa EN `TextCommand` klass som kan konfigureras:

```ruby
# Gammal approach - en klass per kommando
hello = HelloCommand.new
ping = PingCommand.new

# Ny approach - TextCommand med konfigurering
hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
ping = TextCommand.new(name: "ping", description: "Pings", text: "Pong!")
info = TextCommand.new(name: "info", description: "Bot info", text: "I'm a bot!")
```

**Fördelar:**
- Behöver inte skapa en ny klass för varje enkelt textkommando
- Lätt att lägga till nya kommandon
- Mindre kod att underhålla

### Test 1: TextCommand Kan Skapas

#### 🔴 RED - Skriv Testet

Skapa `test/test_text_command.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/text_command'
require_relative '../lib/command'

class TestTextCommand < Minitest::Test
  def test_text_command_can_be_created
    command = TextCommand.new(
      name: "test",
      description: "Test command",
      text: "Test response"
    )

    assert_instance_of TextCommand, command
    assert_kind_of Command, command  # Ärver från Command
    assert_equal "test", command.name
    assert_equal "Test command", command.description
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera TextCommand

**Din uppgift:** Skapa `lib/text_command.rb`

**Vad behöver den?**
- Ladda in command-filen med `require_relative`
- Ärv från `Command` med `< Command`
- Constructor som tar `name:`, `description:`, och `text:` (keyword arguments!)
- Anropa `super(name: name, description: description)`
- Spara `text` i instansvariabel `@text`
- `attr_reader :text` för att komma åt texten
- `execute(event)` metod som anropar `event.respond(@text)`

**Kör testet** - det ska passa!

---

### Test 2: TextCommand Svarar med Text

**Din uppgift:** Lägg till i `test/test_text_command.rb`:

```ruby
def test_text_command_responds_with_text
  command = TextCommand.new(
    name: "greet",
    description: "Greets user",
    text: "Welcome!"
  )
  mock_event = MockEvent.new

  command.execute(mock_event)

  assert_equal 1, mock_event.responses.length
  assert_equal "Welcome!", mock_event.responses.first
end
```

**Kör testet** - det ska passa om din implementation är korrekt!

### Test 3: TextCommand Fungerar för Olika Texter

**Din uppgift:** Lägg till ett test som verifierar att olika `TextCommand`-instanser kan ha olika texter. Skapa två kommandon med olika texter och verifiera att de svarar korrekt.

---

## Städa Upp: Ta Bort Onödig Kod

Nu när vi har `TextCommand`, behöver vi inte längre `HelloCommand` och `PingCommand`!

**Princip:** När du har en bättre, mer generisk lösning - ta bort den gamla koden.

**Din uppgift:** Ta bort följande filer:
- `lib/hello_command.rb`
- `lib/ping_command.rb`
- `test/test_hello_command.rb`
- `test/test_ping_command.rb`

---

## Uppdatera bot.rb med TextCommand

**Din uppgift:**

1. **Uppdatera requires:** Ta bort requires för `hello_command` och `ping_command`, lägg till `require_relative 'lib/text_command'`

2. **Uppdatera kommando-instanser:**

```ruby
# Enkla textkommandon - nu med TextCommand!
hello_command = TextCommand.new(
  name: "hello",
  description: "Says hello",
  text: "Hello!"
)

ping_command = TextCommand.new(
  name: "ping",
  description: "Pings the bot",
  text: "Pong!"
)

# Bonus: Lägg till fler kommandon enkelt!
info_command = TextCommand.new(
  name: "info",
  description: "Shows bot info",
  text: "🤖 I'm a Discord bot built with Ruby and TDD!"
)
```

3. **Lägg till `!info` i case statement** - Annars fungerar det inte i Discord!

4. **Testa i Discord:** `!hello`, `!ping` och `!info` ska alla fungera!

---

## Del 2: Skapa RollCommand med Arguments

Nu kommer den roliga delen - ett kommando som tar **argument**!

### Konceptet: Command Arguments

Användare skriver: `!roll d20`
- Command: `!roll`
- Argument: `d20`

Användare skriver: `!roll 2d6`
- Command: `!roll`
- Argument: `2d6`

### Parsa Dice Notation

Dice notation: `2d6` betyder "rulla 2 tärningar med 6 sidor"
- `d6` = 1 tärning med 6 sidor (implicit 1)
- `2d6` = 2 tärningar med 6 sidor
- `d20` = 1 tärning med 20 sidor

**Regex för att parsa:**
```ruby
notation = "2d6"
match = notation.match(/^(\d+)?d(\d+)$/i)

if match
  count = match[1] ? match[1].to_i : 1  # Default 1 om inget nummer
  sides = match[2].to_i
  # count = 2, sides = 6
end
```

### Test 1: RollCommand Kan Skapas

#### 🔴 RED - Skriv Testet

Skapa `test/test_roll_command.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/roll_command'
require_relative '../lib/command'

class TestRollCommand < Minitest::Test
  def test_roll_command_can_be_created
    command = RollCommand.new

    assert_instance_of RollCommand, command
    assert_kind_of Command, command
    assert_equal "roll", command.name
    assert_equal "Roll dice (e.g. !roll d20, !roll 2d6)", command.description
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera RollCommand

**Din uppgift:** Skapa `lib/roll_command.rb`

**Vad behöver den?**
- Ärv från `Command`
- Constructor utan argument (name och description är hårdkodade)
  - name: "roll"
  - description: "Roll dice (e.g. !roll d20, !roll 2d6)"
- Anropa `super` med name och description
- Override:a `execute(event, args = [])`

**Notera:** `execute` tar nu `args` som andra parameter!

```ruby
def execute(event, args = [])
  # Implementation kommer i nästa steg
end
```

**Kör testet** - det ska passa!

---

### Test 2: RollCommand Rullar d6 by Default

#### 🔴 RED - Skriv Testet

**Din uppgift:** Lägg till i `test/test_roll_command.rb`:

```ruby
def test_roll_command_rolls_d6_by_default
  command = RollCommand.new
  mock_event = MockEvent.new

  command.execute(mock_event, [])  # Inga argument = default d6

  response = mock_event.responses.first
  assert_match /🎲 Rullade 1d6:/, response

  # Extrahera resultat
  number = response.match(/= \*\*(\d+)\*\*/)[1].to_i
  assert_includes 1..6, number
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera Parsing och Rolling

**Din uppgift:** Implementera `execute` metoden i `RollCommand`.

**Vad behöver den göra?**
1. Ta emot `args` array (t.ex. `["d20"]` eller `["2d6"]`)
2. Om args är tom, använd "d6" som default
3. Parsa dice notation med regex (`/^(\d+)?d(\d+)$/i`)
4. Om notation är ogiltig, skicka felmeddelande: `"❌ Ogiltigt format! Använd: !roll d20 eller !roll 2d6"`
5. Rulla tärningar med `rand(1..sides)` för varje tärning
6. Formatera svar: `"🎲 Rullade #{count}d#{sides}: #{results.join(', ')} = **#{total}**"`

**Tips:**
- Använd `count.times.map { rand(1..sides) }` för att rulla flera tärningar
- Använd `results.sum` för att räkna ut totalen
- Kom ihåg `return` efter felmeddelandet!

**Kör testet** - det ska passa!

---

### Test 3-5: Fler RollCommand Tester

**Din uppgift:** Skriv tester för:

1. **test_roll_command_rolls_d20** - Verifiera att `!roll d20` fungerar (resultat mellan 1-20)
2. **test_roll_command_rolls_multiple_dice** - Verifiera att `!roll 2d6` fungerar (resultat mellan 2-12, testa 10 gånger)
3. **test_roll_command_handles_invalid_format** - Verifiera att `!roll potato` ger felmeddelande

Följ samma mönster som Test 2!

**Kör alla tester** - de ska passa!

---

## Del 3: Uppdatera bot.rb för Arguments

Nu behöver vi uppdatera `bot.rb` för att parsa argument och skicka dem till kommandon.

### Uppdatera Message Handler

Öppna `bot.rb` och ersätt message handler:

```ruby
# Hantera meddelanden
bot.message do |event|
  next if event.user.bot_account?

  content = event.content.strip

  # Dela upp i command och arguments
  parts = content.split
  command_name = parts.first&.downcase
  args = parts[1..]  # Allt efter första ordet

  case command_name
  when "!hello"
    hello_command.execute(event)
  when "!ping"
    ping_command.execute(event)
  when "!info"
    info_command.execute(event)
  when "!roll"
    roll_command.execute(event, args)  # Skicka arguments!
  end
end
```

### Lägg Till RollCommand

Innan message handler, lägg till:

```ruby
require_relative 'lib/roll_command'

# Lägg till roll_command efter de andra kommandona
roll_command = RollCommand.new
```

### Testa!

```bash
ruby bot.rb
```

Gå till Discord och testa:
- `!roll` (ska rulla d6)
- `!roll d20` (ska rulla d20)
- `!roll 2d6` (ska rulla 2 tärningar)
- `!roll potato` (ska ge felmeddelande)

---

## Vanliga Misstag

### 1. Glömma att Anropa super

```ruby
# ❌ FEL - Glömmer super
class TextCommand < Command
  def initialize(name:, description:, text:)
    @text = text
    # @name och @description sätts aldrig!
  end
end

# ✅ RÄTT - Anropar super
class TextCommand < Command
  def initialize(name:, description:, text:)
    super(name: name, description: description)
    @text = text
  end
end
```

### 2. Inte Hantera Tomma Arguments

```ruby
# ❌ FEL - Kraschar om args är tom
def execute(event, args)
  notation = args.first  # nil om args är []
  notation.match(/.../)  # Crash! NoMethodError
end

# ✅ RÄTT - Hantera tomma args
def execute(event, args = [])
  notation = args.first || "d6"  # Default värde
  # ...
end
```

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är polymorfism i praktiken?**
   - Svar: Olika klasser (TextCommand, RollCommand) med samma interface (execute) men olika implementation. Alla kan behandlas som Command.

2. **Varför är TextCommand bättre än 10 separata klasser för enkla textkommandon?**
   - Svar: Mindre kod, lättare att underhålla, lätt att lägga till nya kommandon utan nya filer. Konfigurering istället för kod.

3. **När skulle du använda en dedikerad klass (som RollCommand) vs en konfigurerbar klass (som TextCommand)?**
   - Svar: Dedikerad klass när du behöver komplex logik eller tillstånd. Konfigurerbar klass för enkla, repetitiva fall.

4. **Hur hanterar man command arguments?**
   - Svar: Dela upp meddelandet i command och args med `split`, skicka args till execute som andra parametern.

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **EmbedCommand** - Rika Discord meddelanden med färger och fält
- **CoinFlipCommand** - Testa slumpmässighet mellan två värden
- **Command Registry** - Försmak på Uppgift 5!
- **Och mer...**

---

## Nästa Steg

I **Uppgift 5 (Encapsulation & Command Registry)** kommer vi lära oss:
- **Encapsulation** - Gömma implementation details
- **CommandRegistry** - Hantera kommandon dynamiskt
- **!help kommando** - Lista alla tillgängliga kommandon
- **Separation of Concerns** - Dela upp ansvar mellan klasser

**Grattis!** Du har lärt dig polymorfism och byggt ett flexibelt kommandosystem med olika kommandotyper! 🎉

## Resurser

- [Ruby Inheritance Documentation](https://ruby-doc.org/core-3.1.0/Class.html#method-i-3C)
- [Understanding super in Ruby](https://www.rubyguides.com/2018/09/ruby-super-keyword/)
- [Polymorphism in Ruby](https://www.rubyguides.com/2018/11/polymorphism-in-ruby/)
- [When to Use Inheritance](https://thoughtbot.com/blog/back-to-basics-inheritance)
- [Dice Notation Explained](https://en.wikipedia.org/wiki/Dice_notation)
