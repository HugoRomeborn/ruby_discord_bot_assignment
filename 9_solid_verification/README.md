# Uppgift 9: SOLID - Verifiering (LSP, ISP, DIP)

## Översikt

I denna uppgift avslutar du din resa genom **SOLID-principerna**. Du kommer verifiera att din kod följer de tre sista principerna och reflektera över hur hela din bot-arkitektur nu följer alla fem SOLID-principer.

## Förutsättningar

- ✅ Uppgift 8 klar (SOLID - Refactoring)
- ✅ Din `my_discord_bot/` mapp med HookManager, ArrayLogger, och refaktorerad CommandRegistry

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara Liskov Substitution Principle (LSP)
- Förklara Interface Segregation Principle (ISP)
- Förklara Dependency Inversion Principle (DIP)
- Verifiera att kod följer SOLID-principer
- Förstå hur alla SOLID-principer samverkar
- Reflektera över designbeslut från en hel arkitektur

---

## SOLID-Recap

I Uppgift 8 lärde du dig de två första principerna genom refaktorering:

- ✅ **S - Single Responsibility** - Extraherade HookManager från CommandRegistry
- ✅ **O - Open/Closed** - Skapade ArrayLogger utan att ändra CommandRegistry

Nu ska vi täcka de tre sista principerna genom **verifiering**:

- **L - Liskov Substitution Principle** (LSP)
- **I - Interface Segregation Principle** (ISP)
- **D - Dependency Inversion Principle** (DIP)

---

## L - Liskov Substitution Principle

### Konceptet

**"Subklasser ska kunna ersätta sina basklasser utan att ändra programmets korrekthet"**

**Exempel på brott:**
```ruby
class Bird
  def fly; "Flying!"; end
end

class Penguin < Bird
  def fly; raise "Penguins can't fly!"; end  # Bryter kontraktet!
end

make_bird_fly(Penguin.new)  # Kraschar! ❌
```

**Refaktorerad:**
```ruby
class Bird; end
class FlyingBird < Bird
  def fly; "Flying!"; end
end
class Penguin < Bird
  def swim; "Swimming!"; end  # Inget fly-kontrakt att bryta
end
```

Nu kan `Penguin` inte av misstag användas där `fly` förväntas!

---

## Del 1: LSP i Vår Bot

Låt oss verifiera att våra logger-klasser följer LSP!

### Konceptet: Logger-Kontraktet

Alla loggers måste ha samma interface:
- `info(message)` - Logga info-meddelande
- `warn(message)` - Logga varning
- `error(message)` - Logga fel

Och de får **INTE** kasta exceptions för normala anrop!

### Test 1: Alla Loggers Implementerar Interface

Skapa `test/test_logger_contract.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/logger'
require_relative '../lib/file_logger'
require_relative '../lib/array_logger'

class TestLoggerContract < Minitest::Test
  def setup
    @log_file = "test_contract.log"
    File.delete(@log_file) if File.exist?(@log_file)
  end

  def teardown
    File.delete(@log_file) if File.exist?(@log_file)
  end

  def test_all_loggers_implement_info
    loggers = [
      Logger.new,
      FileLogger.new(@log_file),
      ArrayLogger.new
    ]

    loggers.each do |logger|
      assert_respond_to logger, :info, "#{logger.class} should implement info"
      assert_respond_to logger, :warn, "#{logger.class} should implement warn"
      assert_respond_to logger, :error, "#{logger.class} should implement error"
    end
  end
end
```

**Kör testet** - det ska passa!

---

### Test 2: Alla Loggers Kan Användas Utbytbart

**Din uppgift:** Lägg till test som verifierar att alla loggers kan användas utan att krascha:

```ruby
def test_all_loggers_can_be_used_interchangeably
  loggers = [
    Logger.new,
    FileLogger.new(@log_file),
    ArrayLogger.new
  ]

  loggers.each do |logger|
    # Ska INTE krascha
    logger.info("Test message")
    logger.warn("Warning")
    logger.error("Error")
  end
end
```

**Kör testet** - det ska passa! Detta bevisar att alla loggers följer LSP.

---

### Test 3: Commands Följer LSP

Låt oss verifiera att alla commands kan ersätta varandra:

**Din uppgift:** Lägg till test i `test/test_command_registry.rb`:

```ruby
def test_all_commands_can_be_registered_and_executed
  registry = CommandRegistry.new
  mock_event = MockEvent.new

  commands = [
    TextCommand.new(name: "text", description: "Text", text: "Hello!"),
    RollCommand.new
  ]

  commands.each do |command|
    # Alla commands kan registreras
    registry.register(command)

    # Alla commands kan hittas
    found = registry.find(command.name)
    assert_equal command, found

    # Alla commands kan exekveras (med args för RollCommand)
    if command.is_a?(RollCommand)
      command.execute(mock_event, ["d6"])
    else
      command.execute(mock_event)
    end
  end

  # Verifiera att båda commands kördes
  assert_equal 2, mock_event.responses.length
end
```

**Kör testet** - det ska passa!

**Detta bevisar LSP:** Alla command-typer kan användas utbytbart i CommandRegistry!

---

## I - Interface Segregation Principle

### Konceptet

**"Klasser ska inte tvingas implementera metoder de inte använder"**

**Exempel på brott:**
```ruby
class Robot < Worker
  def work; "Working..."; end
  def eat; raise "Robots don't eat!"; end  # Tvingad implementera!
end
```

**Refaktorerad:**
```ruby
module Workable
  def work; raise NotImplementedError; end
end
module Eatable
  def eat; raise NotImplementedError; end
end

class Human
  include Workable  # Båda
  include Eatable
end

class Robot
  include Workable  # Bara work!
end
```

Nu implementerar varje klass bara de interfaces den behöver!

---

## Del 2: ISP i Vår Bot

ISP handlar om att ha små, fokuserade interfaces. Låt oss analysera vår kod.

### Analys: Logger Interface

**Vårt logger-interface:**
```ruby
logger.info(message)
logger.warn(message)
logger.error(message)
```

**Frågor:**
1. Är detta interface minimalt? **Ja** - bara 3 metoder för 3 log-nivåer.
2. Måste alla loggers implementera alla metoder? **Ja** - annars bryter LSP.
3. Kan vi dela upp interfacet? **Nej** - alla metoder behövs av konsumenter.

**Detta är bra ISP!** Minimalt, fokuserat interface.

---

### Analys: Command Interface

**Vårt command-interface:**
```ruby
command.name
command.description
command.execute(event, args = [])
```

**Problem:** Inte alla commands använder `args`!

```ruby
class TextCommand < Command
  def execute(event, args = [])
    event.respond(@text)
    # args används INTE
  end
end

class RollCommand < Command
  def execute(event, args = [])
    # args används ✅
  end
end
```

**Är detta ett ISP-brott?**

**Svar: NEJ!** I Ruby är optional parameters (`args = []`) acceptabelt. ISP handlar mer om att inte tvinga klasser att implementera MÅNGA metoder de inte behöver.

**Ruby-perspektiv:**
- Optional parameters är idiomatiskt Ruby
- Ingen performance-cost
- Flexibilitet utan komplexitet

**Om vi hade 10+ metoder där bara hälften användes - DÅ skulle det vara ett problem!**

---

### Test: Verifiera Minimala Interfaces

**Din uppgift:** Skapa test som verifierar att våra interfaces är minimala:

```ruby
# test/test_interfaces.rb
require_relative 'spec_helper'
require_relative '../lib/logger'
require_relative '../lib/command'

class TestInterfaces < Minitest::Test
  def test_logger_interface_is_minimal
    logger = Logger.new

    # Loggers ska bara ha 3 publika metoder (+ messages för testning)
    public_methods = logger.public_methods(false)

    assert_includes public_methods, :info
    assert_includes public_methods, :warn
    assert_includes public_methods, :error

    # Inte fler än nödvändigt (messages är för testning)
    assert public_methods.length <= 4, "Logger interface bör vara minimalt"
  end

  def test_command_interface_is_minimal
    command = TextCommand.new(name: "test", description: "Test", text: "Hi")

    # Commands ska ha execute, name, description
    assert_respond_to command, :execute
    assert_respond_to command, :name
    assert_respond_to command, :description

    # Execute ska acceptera både 1 och 2 argument (event, args)
    mock_event = MockEvent.new
    command.execute(mock_event)  # Fungerar utan args
    command.execute(mock_event, [])  # Fungerar med args
  end
end
```

**Kör testet** - det ska passa!

---

## D - Dependency Inversion Principle

### Konceptet

**"Beroende på abstraktioner, inte konkreta klasser"**

**Exempel på brott:**
```ruby
class UserService
  def initialize
    @database = MySQLDatabase.new  # Hårt kopplad till MySQL!
  end
end
```

**Refaktorerad (med DI):**
```ruby
class UserService
  def initialize(database)
    @database = database  # Vilken databas som helst med .save()!
  end
end

# Användning
service = UserService.new(MySQLDatabase.new)
service = UserService.new(PostgreSQLDatabase.new)
```

Nu beror UserService på abstraktionen "något med save-metod", inte konkreta klasser!

---

## Del 3: DIP i Vår Bot - Vi Följer Det Redan!

Tack vare Dependency Injection (Uppgift 7) följer vi redan DIP!

### Exempel: CommandRegistry

```ruby
class CommandRegistry
  def initialize(logger: nil, hook_manager: nil)
    @logger = logger              # Abstraktion: "något med .info()"
    @hook_manager = hook_manager  # Abstraktion: "något med .before, .after"
  end
end
```

**CommandRegistry beror INTE på:**
- `Logger` klassen (konkret)
- `FileLogger` klassen (konkret)
- `ArrayLogger` klassen (konkret)
- `HookManager` klassen (konkret)

**CommandRegistry beror på:**
- Abstraktionen "ett objekt med .info(), .warn(), .error()"
- Abstraktionen "ett objekt med .before, .after, .trigger_before, .trigger_after"

**Detta är DIP!**

---

### Test: Verifiera DIP med Mock

Låt oss bevisa DIP genom att använda en helt ny logger som aldrig funnits innan:

Skapa `test/test_mock_logger.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/command_registry'
require_relative '../lib/hook_manager'

# En helt ny logger-typ, skapad bara för testet
class MockLogger
  attr_reader :info_count, :warn_count, :error_count

  def initialize
    @info_count = 0
    @warn_count = 0
    @error_count = 0
  end

  def info(message)
    @info_count += 1
  end

  def warn(message)
    @warn_count += 1
  end

  def error(message)
    @error_count += 1
  end
end

class TestMockLogger < Minitest::Test
  def test_command_registry_works_with_mock_logger
    mock_logger = MockLogger.new
    hook_manager = HookManager.new
    registry = CommandRegistry.new(logger: mock_logger, hook_manager: hook_manager)

    hook_manager.before { |name| mock_logger.info("Before: #{name}") }
    hook_manager.trigger_before(:test)

    assert_equal 1, mock_logger.info_count
  end
end
```

**Kör testet** - det ska passa!

**Detta bevisar DIP:** CommandRegistry fungerar med MockLogger trots att MockLogger aldrig fanns när CommandRegistry skrevs! CommandRegistry beror bara på abstraktionen "något med .info()".

---

### Test: DIP med Mock HookManager

**Din uppgift:** Skapa en MockHookManager och verifiera att CommandRegistry fungerar med den:

```ruby
# I test/test_mock_logger.rb
class MockHookManager
  attr_reader :before_count, :after_count

  def initialize
    @before_count = 0
    @after_count = 0
  end

  def before(&block)
    @before_count += 1
  end

  def after(&block)
    @after_count += 1
  end

  def trigger_before(args = nil)
    # Mock implementation
  end

  def trigger_after(args = nil)
    # Mock implementation
  end
end

def test_command_registry_works_with_mock_hook_manager
  mock_hook_manager = MockHookManager.new
  registry = CommandRegistry.new(hook_manager: mock_hook_manager)

  assert_equal mock_hook_manager, registry.hook_manager
end
```

**Kör testet** - det ska passa!

---

## Sammanfattning: SOLID i Hela Din Bot

Nu har du lärt dig alla SOLID-principer! Låt oss se hur hela din bot följer dem:

### S - Single Responsibility ✅

**Varje klass har ETT ansvar:**
- `Command` - Representera ett kommando
- `TextCommand` - Exekvera textkommando
- `RollCommand` - Exekvera tärningsrullning
- `CommandRegistry` - Hantera kommando-registrering
- `HookManager` - Hantera hooks
- `Logger` - Logga till terminal
- `FileLogger` - Logga till fil
- `ArrayLogger` - Logga till array (för tester)

### O - Open/Closed ✅

**Öppen för utökning, stängd för modifiering:**
- Kan lägga till nya logger-typer utan att ändra CommandRegistry
- Kan lägga till nya command-typer utan att ändra CommandRegistry
- Bevisat genom: FileLogger, ArrayLogger, MockLogger

### L - Liskov Substitution ✅

**Subklasser kan ersätta basklasser:**
- Alla loggers (Logger, FileLogger, ArrayLogger) kan ersätta varandra
- Alla commands (TextCommand, RollCommand) kan ersätta varandra
- Verifierat genom contract testing

### I - Interface Segregation ✅

**Minimala, fokuserade interfaces:**
- Logger-interface: bara 3 metoder (info, warn, error)
- Command-interface: minimal (name, description, execute)
- Inga klasser tvingas implementera onödiga metoder

### D - Dependency Inversion ✅

**Beroende på abstraktioner, inte konkreta klasser:**
- CommandRegistry beror på logger-interface, inte Logger-klassen
- CommandRegistry beror på hook-manager-interface, inte HookManager-klassen
- Bevisat med MockLogger och MockHookManager

**Din bot har nu en fullständig SOLID-arkitektur!** 🎉

---

## Reflektionsövning: Designresan

Låt oss titta på hur din bot utvecklats från Uppgift 0 till nu:

### Uppgift 0-1: Grunderna
- Hårdkodade if-statements i bot.rb
- Inga klasser, ingen struktur

### Uppgift 2-3: Klasser & Arv
- Command-klasser introducerades
- Arv för att dela kod (DRY)

### Uppgift 4: Polymorfism
- Olika command-typer med samma interface
- Början på flexibilitet

### Uppgift 5: Encapsulation
- CommandRegistry kapslade in command-hantering
- Men: hade för många ansvarsområden

### Uppgift 6: Blocks & Hooks
- Hooks för callbacks
- Men: hårdkodade i registry

### Uppgift 7: Dependency Injection
- Logger injiceras istället för hårdkodas
- Öppnade för OCP
- Uppnådde DIP

### Uppgift 8: SRP & OCP
- Extraherade HookManager (SRP)
- Skapade ArrayLogger (OCP)

### Uppgift 9: LSP, ISP, DIP
- Verifierade att arkitekturen följer alla SOLID-principer
- Reflekterade över designbeslut

**Se hur varje steg byggde på det föregående!**

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är Liskov Substitution Principle?**
   - Svar: Subklasser ska kunna ersätta basklasser utan att bryta programmet.

2. **Hur verifierar man LSP?**
   - Svar: Contract testing - verifiera att alla subklasser implementerar samma interface och beter sig korrekt.

3. **Vad är Interface Segregation Principle?**
   - Svar: Små, fokuserade interfaces. Klasser ska inte tvingas implementera metoder de inte behöver.

4. **När är optional parameters OK enligt ISP?**
   - Svar: I Ruby är optional parameters idiomatiskt och OK. ISP handlar om att inte ha för MÅNGA onödiga metoder.

5. **Vad är Dependency Inversion Principle?**
   - Svar: Beroende på abstraktioner (interfaces), inte konkreta klasser.

6. **Hur uppnår man DIP?**
   - Svar: Dependency Injection - injicera dependencies istället för att skapa dem internt.

7. **Hur samverkar alla SOLID-principer?**
   - Svar: De förstärker varandra - SRP gör klasser fokuserade, OCP gör dem utökningsbara, LSP gör dem utbytbara, ISP håller interfaces enkla, DIP gör dem flexibla.

---

## Vanliga Misstag

### 1. Tro att SOLID Betyder Perfekt Kod

❌ Over-engineering: Skapa abstraktioner för allt "för att följa SOLID"
✅ Pragmatisk SOLID: Använd SOLID när det löser riktiga problem

SOLID är principer, inte lagar. Använd sunt förnuft!

### 2. Glömma Att Tester Är Dokumentation

❌ Tester som bara verifierar implementation: `logger.instance_variable_get(:@messages)`
✅ Tester som verifierar beteende och kontrakt: `loggers.each { |logger| logger.info("test") }`

### 3. Använda SOLID Retroaktivt Utan Tester

❌ Refaktorera utan tester: "Jag ska göra koden SOLID!" → Ändrar massa → Kraschar
✅ TDD-approach: Tester gröna → Refaktorera → Tester fortfarande gröna

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **SOLID Violations Kata** - Identifiera och fixa SOLID-brott i given kod
- **Design Patterns** - Strategy, Observer, Factory som bygger på SOLID
- **Refactoring Legacy Code** - Tillämpa SOLID på kod utan tester
- **Och mer...**

---

## Slutord: Din OOP-Resa

**Grattis!** Du har nu gått igenom en komplett OOP-resa:

- ✅ **TDD** - Röd-Grön-Refaktorera
- ✅ **Klasser & Objekt** - Grundläggande OOP
- ✅ **Arv** - Dela kod mellan klasser
- ✅ **Polymorfism** - Samma interface, olika beteende
- ✅ **Encapsulation** - Göm implementation details
- ✅ **Symbols & Blocks** - Ruby-specifika features
- ✅ **Dependency Injection** - Flexibel, testbar kod
- ✅ **SOLID** - Designprinciper för underhållbar kod

**Din Discord-bot är nu:**
- Välstrukturerad
- Testbar
- Flexibel
- Utökningsbar
- Underhållbar

**Möjliga nästa steg:**
- **Designmönster** - Strategy, Observer, Factory, etc.
- **Webserver-projekt** - Bygg din egen Sinatra-klon med SOLID
- **Avancerad testing** - Integration tests, end-to-end tests
- **Deployment** - Kör din bot i molnet

Du har nu verktyg och kunskaper för att bygga professionella, väldesignade system! 🎉

## Resurser

- [SOLID Principles Explained](https://medium.com/rubyinside/s-o-l-i-d-the-first-5-principles-of-object-oriented-design-with-ruby-examples-fc2ac3b34b9)
- [Liskov Substitution Principle](https://thoughtbot.com/blog/back-to-basics-solid)
- [Interface Segregation Principle](https://www.rubyguides.com/2018/10/solid-principles/)
- [Dependency Inversion Principle](https://thoughtbot.com/blog/dependency-injection-in-ruby)
- [Clean Code by Robert C. Martin](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
- [Practical Object-Oriented Design in Ruby](https://www.poodr.com/)
