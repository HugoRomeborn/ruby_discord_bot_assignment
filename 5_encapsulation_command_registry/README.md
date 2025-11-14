# Uppgift 5: Encapsulation & Command Registry

## Översikt

I denna uppgift ska du lära dig **encapsulation** (inkapsling) genom att bygga en `CommandRegistry` klass som hanterar alla kommandon. Du kommer också skapa ett `!help` kommando som listar alla tillgängliga kommandon.

## Förutsättningar

- ✅ Uppgift 4 klar (Polymorphism & Command Types)
- ✅ Din `my_discord_bot/` mapp med `Command`, `TextCommand`, `RollCommand`

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara vad encapsulation är och varför det är viktigt
- Använda `private` för att gömma implementation details
- Skapa klasser med tydliga publika interface
- Förstå separation of concerns
- Bygga en registry pattern

---

## Koncept: Encapsulation (Inkapsling)

### Grunderna

**Läs först:** [Inkapsling i kursboken](https://ntijoh.github.io/Programmering_2/#_inkapsling)

Kursboken förklarar grunderna i encapsulation:
- Vad inkapsling är (att gömma implementation details)
- Getters och setters (attr_reader, attr_writer, attr_accessor)
- Public vs private metoder
- Varför det är viktigt

**Läs kapitlet innan du fortsätter!** Nedan kompletterar vi med specifika detaljer för denna uppgift.

---

### Encapsulation i Denna Uppgift

I denna uppgift använder vi encapsulation för att bygga `CommandRegistry` - en klass som hanterar alla kommandon.

**Vad kommer vi göra?**
- Gömma hur kommandon lagras (implementation detail)
- Exponera endast metoder som användare behöver (public interface)
- Använda private metoder för intern logik

**Utan encapsulation (dåligt):**
```ruby
# ❌ Direkt access till internal state
registry.commands["hello"] = hello_command  # Vad händer om vi ändrar hur vi lagrar commands?
registry.commands.delete("ping")  # Kan ta sönder saker!
```

**Med encapsulation (bra):**
```ruby
# ✅ Kontrollerad access via metoder
registry.register(hello_command)  # Klassen kontrollerar hur data lagras
registry.find("!hello")  # Klassen hanterar sökning
```

**Fördelar:**
- ✅ **Kontroll** - Registry kontrollerar hur kommandon lagras
- ✅ **Flexibilitet** - Kan ändra implementation utan att bryta kod
- ✅ **Enkelhet** - Användare behöver bara veta om public interface

---

## Koncept: Separation of Concerns

**Separation of Concerns** betyder att olika delar av koden har olika ansvarsområden.

**Nuvarande problem i `bot.rb`:**
```ruby
# ❌ bot.rb gör för mycket:
# 1. Skapar kommandon
# 2. Håller reda på kommandon
# 3. Matchar meddelanden mot kommandon
# 4. Hanterar Discord events

case command_name
when "!hello"
  hello_command.execute(event)
when "!ping"
  ping_command.execute(event)
when "!info"
  info_command.execute(event)
when "!roll"
  roll_command.execute(event, args)
end
# Varje gång vi lägger till kommando måste vi ändra här!
```

**Lösning med CommandRegistry:**
```ruby
# ✅ CommandRegistry ansvarar för att hålla reda på kommandon
registry = CommandRegistry.new
registry.register(hello_command)
registry.register(ping_command)

# bot.rb blir enklare
command = registry.find(command_name)
command.execute(event, args) if command
```

**Fördelar:**
- ✅ Enklare att lägga till kommandon (ingen case statement)
- ✅ Lätt att lista alla kommandon (för !help)
- ✅ bot.rb blir kortare och tydligare
- ✅ Varje klass har ett tydligt ansvar

---

## TDD-Approach: Testa Encapsulation

**Testa det publika interfacet:**
```ruby
# ✅ Testa publika metoder
def test_can_register_command
  registry = CommandRegistry.new
  command = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")

  registry.register(command)
  found = registry.find("!hello")

  assert_equal command, found
end
```

**Testa INTE privata metoder direkt:**
```ruby
# ❌ Testa INTE privata metoder
def test_normalize_name  # Private method
  # Detta är implementation detail
end
```

**Privata metoder testas indirekt via publika metoder:**
```ruby
# ✅ Private normalize_name testas via public find
def test_find_is_case_insensitive
  registry.register(command)

  assert_equal command, registry.find("!HELLO")  # Testar normalize_name indirekt
  assert_equal command, registry.find("!hello")
end
```

---

## Del 1: Skapa CommandRegistry

Nu ska vi bygga `CommandRegistry` klassen med TDD!

### Test 1: Registry Kan Skapas

#### 🔴 RED - Skriv Testet

Skapa `test/test_command_registry.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/command_registry'

class TestCommandRegistry < Minitest::Test
  def test_registry_can_be_created
    registry = CommandRegistry.new

    assert_instance_of CommandRegistry, registry
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera CommandRegistry

**Din uppgift:** Skapa `lib/command_registry.rb`

**Vad behöver den?**
- En `CommandRegistry` klass
- Constructor (`initialize`) som skapar en tom hash `@commands`

**Kör testet** - det ska passa!

---

### Test 2: Kan Registrera Kommandon

#### 🔴 RED - Skriv Testet

**Din uppgift:** Lägg till i `test/test_command_registry.rb`:

```ruby
require_relative '../lib/text_command'
require_relative '../lib/command'

def test_can_register_command
  registry = CommandRegistry.new
  command = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")

  registry.register(command)

  # Verifiera att kommandot registrerades (vi testar detta via find i nästa test)
  # För nu, bara att det inte kraschar
  assert true
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera register

**Din uppgift:** Lägg till `register` metoden i `CommandRegistry`.

**Vad behöver den göra?**
- Ta emot ett command objekt som parameter
- Spara det i `@commands` hash med `"!#{command.name}"` som nyckel

**Kör testet** - det ska passa!

---

### Test 3: Kan Hitta Registrerade Kommandon

#### 🔴 RED - Skriv Testet

```ruby
def test_can_find_registered_command
  registry = CommandRegistry.new
  command = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  registry.register(command)

  found = registry.find("!hello")

  assert_equal command, found
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera find

**Din uppgift:** Lägg till `find` metoden.

**Vad behöver den göra?**
- Ta emot ett command name som parameter (t.ex. "!hello")
- Returnera kommandot från `@commands` hash
- Returnera `nil` om kommandot inte finns

**Kör testet** - det ska passa!

---

### Test 4: find Returnerar nil för Okända Kommandon

**Din uppgift:** Skriv ett test som verifierar att `find` returnerar `nil` när man söker efter ett kommando som inte finns.

**Kör testet** - det ska passa om din implementation är korrekt!

---

### Test 5: Kan Lista Alla Kommandon

För `!help` kommandot behöver vi kunna lista alla kommandon.

#### 🔴 RED - Skriv Testet

```ruby
def test_can_list_all_commands
  registry = CommandRegistry.new
  hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  ping = TextCommand.new(name: "ping", description: "Pings", text: "Pong!")

  registry.register(hello)
  registry.register(ping)

  commands = registry.all

  assert_equal 2, commands.length
  assert_includes commands, hello
  assert_includes commands, ping
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera all

**Din uppgift:** Lägg till `all` metoden.

**Vad ska den returnera?**
- En array med alla registrerade kommandon

**Kör testet** - det ska passa!

---

## Del 2: Lägg Till Encapsulation med Private Methods

Nu ska vi lägga till en privat metod som normaliserar command names.

### Problemet

Just nu måste användaren skriva exakt "!hello" (med `!` och lowercase). Vi vill acceptera:
- `!HELLO`
- `!Hello`
- `  !hello  ` (med whitespace)

### Test 6: find Är Case-Insensitive och Flexibel

#### 🔴 RED - Skriv Testet

```ruby
def test_find_is_case_insensitive_and_flexible
  registry = CommandRegistry.new
  command = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  registry.register(command)

  # Olika varianter ska alla hitta samma kommando
  assert_equal command, registry.find("!hello")
  assert_equal command, registry.find("!HELLO")
  assert_equal command, registry.find("  !Hello  ")
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Lägg Till Private normalize_name

**Din uppgift:**

1. **Lägg till en privat metod `normalize_name(name)` som:**
   - Gör command names case-insensitive
   - Hanterar extra whitespace
   - Returnerar en normaliserad sträng

2. **Uppdatera `find` metoden:**
   - Använd `normalize_name` innan du kollar i `@commands`

3. **Placera `private` keyword rätt:**
   - Private metoder kommer efter all public kod

**Kör testet** - det ska passa!

---

## Del 3: Skapa HelpCommand

Nu ska vi skapa ett `!help` kommando som listar alla kommandon.

### Test 1: HelpCommand Kan Skapas

#### 🔴 RED - Skriv Testet

Skapa `test/test_help_command.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/help_command'
require_relative '../lib/command'
require_relative '../lib/command_registry'

class TestHelpCommand < Minitest::Test
  def test_help_command_can_be_created
    registry = CommandRegistry.new
    command = HelpCommand.new(registry: registry)

    assert_instance_of HelpCommand, command
    assert_kind_of Command, command
    assert_equal "help", command.name
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera HelpCommand

**Din uppgift:** Skapa `lib/help_command.rb`

**Vad behöver den?**
- Ärv från `Command`
- Constructor som tar `registry:` som keyword argument
- Anropa `super(name: "help", description: "Shows all available commands")`
- Spara registry i instansvariabel `@registry`
- Tom `execute(event)` metod (implementation kommer i nästa test)

**Kör testet** - det ska passa!

---

### Test 2: HelpCommand Listar Alla Kommandon

#### 🔴 RED - Skriv Testet

```ruby
def test_help_command_lists_all_commands
  registry = CommandRegistry.new
  hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  ping = TextCommand.new(name: "ping", description: "Pings bot", text: "Pong!")

  registry.register(hello)
  registry.register(ping)

  help_command = HelpCommand.new(registry: registry)
  mock_event = MockEvent.new

  help_command.execute(mock_event)

  response = mock_event.responses.first

  # Verifiera att responsen innehåller alla kommandon
  assert_includes response, "!hello"
  assert_includes response, "Says hello"
  assert_includes response, "!ping"
  assert_includes response, "Pings bot"
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera execute

**Din uppgift:** Implementera `execute` metoden i `HelpCommand`.

**Vad ska den göra?**
1. Hämta alla kommandon från registry med `@registry.all`
2. Bygg en sträng med alla kommandon
3. Skicka den med `event.respond`

**Kör testet** - det ska passa!

---

## Del 4: Uppdatera bot.rb med CommandRegistry

Nu ska vi integrera `CommandRegistry` i bot.rb och göra koden mycket renare!

### Innan: bot.rb med case statement

```ruby
# Gammalt sätt - case statement
case command_name
when "!hello"
  hello_command.execute(event)
when "!ping"
  ping_command.execute(event)
when "!info"
  info_command.execute(event)
when "!roll"
  roll_command.execute(event, args)
end
```

### Efter: bot.rb med CommandRegistry

**Din uppgift:** Refaktorera `bot.rb` för att använda CommandRegistry.

**Steg-för-steg:**

1. **Lägg till requires:**
   - `require_relative 'lib/command_registry'`
   - `require_relative 'lib/help_command'`

2. **Skapa registry (efter bot-initialisering):**
   - Skapa en `CommandRegistry` instans

3. **Registrera dina kommandon:**
   - Skapa TextCommand instanser för hello, ping, info
   - Skapa RollCommand instans
   - Registrera alla med `registry.register(command)`
   - Skapa HelpCommand (med `registry: registry`)
   - Registrera även HelpCommand

4. **Ersätt case statement med registry lookup:**
   - Ta bort hela `case command_name ... end` blocket
   - Använd `registry.find(command_name)` istället
   - Om kommando hittas, anropa `command.execute(event, args)` (vissa behöver args)

**Tips:**
- RollCommand behöver args, andra kommandon inte
- Du kan kolla `command.is_a?(RollCommand)` för att avgöra

### Testa!

```bash
ruby bot.rb
```

Gå till Discord och testa:
- `!help` (ska lista alla kommandon)
- `!HELLO` (ska fungera trots uppercase)
- `!roll 2d6` (ska fungera)

---

## Vanliga Misstag

### 1. Glömma Lägga Till ! i Registry Keys

```ruby
# ❌ FEL - Inkonsistenta nycklar
def register(command)
  @commands[command.name] = command  # "hello" utan !
end

def find(command_name)
  @commands[command_name]  # "!hello" med !
end
# Hittar aldrig kommandot!

# ✅ RÄTT - Konsekvent med !
def register(command)
  @commands["!#{command.name}"] = command
end
```

### 2. Anropa Private Metoder Fel

```ruby
# ❌ FEL - Försöker anropa private method
registry.normalize_name("hello")  # NoMethodError: private method

# ✅ RÄTT - Private metoder anropas bara inifrån klassen
def find(command_name)
  normalized = normalize_name(command_name)  # OK inifrån klassen
  @commands[normalized]
end
```

### 3. Testa Private Metoder Direkt

```ruby
# ❌ FEL - Testar private method
def test_normalize_name
  registry = CommandRegistry.new
  result = registry.normalize_name("HELLO")  # Kan inte anropa private
end

# ✅ RÄTT - Testa via public interface
def test_find_normalizes_names
  registry.register(command)
  assert_equal command, registry.find("HELLO")  # Testar indirekt
end
```

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är encapsulation och varför är det viktigt?**
   - Svar: Att gömma implementation details och endast exponera nödvändiga metoder. Ger kontroll, flexibilitet och enklare API.

2. **Vad är skillnaden mellan public och private metoder?**
   - Svar: Public kan anropas av alla, private bara inifrån klassen. Private används för implementation details.

3. **Varför är CommandRegistry bättre än en case statement i bot.rb?**
   - Svar: Separation of concerns, lättare att lägga till kommandon, kan lista alla kommandon, renare kod.

4. **Hur testar man private metoder?**
   - Svar: Indirekt via public metoder. Private metoder är implementation details som inte ska testas direkt.

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **Command Aliases** - Flera namn för samma kommando (!h för !help)
- **Command Categories** - Gruppera kommandon (Fun, Admin, Info)
- **Permissions System** - Admin-only kommandon
- **Och mer...**

---

## Nästa Steg

I **Uppgift 6 (Symbols & Blocks)** kommer vi lära oss:
- **Symbols** - Vad de är och varför de är bättre som hash keys
- **Ruby blocks** - yield, block_given?
- **Callbacks** - before_execute, after_execute hooks
- **Custom iterators** - CommandRegistry#each

**Grattis!** Du har lärt dig encapsulation och byggt ett flexibelt command registry system! 🎉

## Resurser

- [Ruby Encapsulation](https://www.rubyguides.com/2018/10/encapsulation-in-ruby/)
- [Public, Private, Protected](https://www.rubyguides.com/2018/10/method-visibility/)
- [Ruby Style Guide - Access Modifiers](https://rubystyle.guide/#access-modifiers-indentation)
- [Separation of Concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)
- [Registry Pattern](https://www.sourcecodeexamples.net/2018/04/registry-design-pattern.html)
