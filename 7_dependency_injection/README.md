# Uppgift 7: Dependency Injection

## Översikt

I denna uppgift ska du lära dig **Dependency Injection (DI)** - ett kraftfullt mönster för att skapa flexibel och testbar kod. Du kommer refaktorera din bot från hårdkodade dependencies till injicerade dependencies.

## Förutsättningar

- ✅ Uppgift 6 klar (Symbols & Blocks)
- ✅ Din `my_discord_bot/` mapp med CommandRegistry och hooks

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara vad Dependency Injection är och varför det är viktigt
- Identifiera hårdkodade dependencies i kod
- Refaktorera kod för att använda DI
- Förstå hur DI förbättrar testbarhet
- Skapa mockbara dependencies för tester
- Använda optional dependencies

---

## Koncept: Dependency Injection

### Vad är en Dependency?

En **dependency** är något din klass behöver för att fungera:

```ruby
class CommandRegistry
  def initialize
    @commands = {}
    @logger = Logger.new  # CommandRegistry är BEROENDE av Logger
  end

  def trigger_before_hooks(name)
    @logger.info("Running: #{name}")  # Använder loggern
  end
end
```

Här är `Logger` en dependency - CommandRegistry kan inte logga utan den.

### Problemet med Hårdkodade Dependencies

**Nuvarande kod (från Uppgift 6):**
```ruby
registry.before_execute do |command_name|
  puts "▶️  Running: !#{command_name}"  # Hårdkodat puts!
end
```

**Ett värre exempel - hårdkodat inne i klassen:**
```ruby
class CommandRegistry
  def initialize
    @logger = Logger.new  # CommandRegistry MÅSTE känna till Logger-klassen
  end

  def trigger_before_hooks(name)
    @logger.info("Running: #{name}")
  end
end
```

**Problem:**

**1. Tight Coupling (Hårt Kopplad)**
- CommandRegistry är **hårt kopplad** till Logger-klassen
- Kan inte använda CommandRegistry utan Logger
- Om Logger-klassens namn ändras, måste vi ändra CommandRegistry
- Om Logger kräver parametrar (t.ex. filnamn), måste CommandRegistry veta det

**2. Svår att Testa**
- ❌ Omöjligt att testa utan att skapa en riktig Logger
- ❌ Kan inte mocka loggern i tester
- ❌ Tester blir långsamma om Logger skriver till fil/databas

**3. Oflexibel**
- ❌ Kan inte enkelt byta från Logger till FileLogger
- ❌ Kan inte stänga av loggning
- ❌ Kan inte använda olika loggers i olika miljöer (test vs produktion)

**4. Bryter Single Responsibility Principle**
- CommandRegistry ansvarar för att SKAPA logger (inte bara använda den)
- Vad om Logger behöver konfiguration? CommandRegistry måste veta det!

### Konceptet: Coupling (Koppling)

**Tight Coupling (Hårt Kopplad):**
```ruby
class A
  def initialize
    @b = B.new  # A känner till B's klassnamn
  end
end
```
- A kan inte existera utan B
- Om B ändras, måste A ofta ändras
- Svårt att testa A isolerat

**Loose Coupling (Löst Kopplad):**
```ruby
class A
  def initialize(b)
    @b = b  # A vet inte VAD b är, bara att den finns
  end
end
```
- A bryr sig inte om B's klassnamn
- A kan användas med vad som helst som har rätt interface
- Lätt att testa A med mock-objekt

### Lösningen: Dependency Injection

Istället för att **skapa** dependencies inne i klassen, **skicka in** dem:

```ruby
# Hårdkodat (dåligt)
class CommandRegistry
  def initialize
    @logger = Logger.new  # Skapar logger här
  end
end

# Dependency Injection (bra)
class CommandRegistry
  def initialize(logger: nil)
    @logger = logger  # Logger skickas in utifrån
  end
end

# Användning
logger = Logger.new
registry = CommandRegistry.new(logger: logger)  # Injicera!
```

**Fördelar:**
- ✅ Testbart - kan skicka in mock logger
- ✅ Flexibelt - lätt att byta implementation
- ✅ Tydligt - ser exakt vad klassen behöver
- ✅ Optional - kan skicka in `nil` för att stänga av

---

## Del 1: Skapa Logger-klass

Först behöver vi en Logger-klass att injicera!

### Test 1: Logger Kan Logga Meddelanden

#### 🔴 RED - Skriv Testet

Skapa `test/test_logger.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/logger'

class TestLogger < Minitest::Test
  def test_logger_can_log_info
    logger = Logger.new

    # Loggar ska spara meddelanden
    logger.info("Test message")

    assert_equal 1, logger.messages.length
    assert_equal "INFO: Test message", logger.messages.first
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera Logger

**Din uppgift:** Skapa `lib/logger.rb`

**Vad behöver den?**
- `initialize` - Skapa `@messages = []` för att spara meddelanden
- `info(message)` - Lägg till `"INFO: #{message}"` i `@messages` array
- `attr_reader :messages` - Så vi kan läsa meddelanden i tester
- `info` metoden ska också `puts` meddelandet (så vi ser det i terminalen)

**Kör testet** - det ska passa!

---

### Test 2: Logger Har Flera Nivåer

**Din uppgift:** Lägg till test för andra log-nivåer:

```ruby
def test_logger_has_multiple_levels
  logger = Logger.new

  logger.info("Info message")
  logger.warn("Warning message")
  logger.error("Error message")

  assert_equal 3, logger.messages.length
  assert_equal "INFO: Info message", logger.messages[0]
  assert_equal "WARN: Warning message", logger.messages[1]
  assert_equal "ERROR: Error message", logger.messages[2]
end
```

**Implementera:** Lägg till `warn(message)` och `error(message)` metoder i Logger.

**Kör testet** - det ska passa!

---

## Del 2: Injicera Logger i CommandRegistry

Nu ska vi refaktorera CommandRegistry för att ta emot en injicerad logger!

### Test 1: Registry Tar Emot Logger

#### 🔴 RED - Uppdatera Testet

Öppna `test/test_command_registry.rb` och lägg till:

```ruby
def test_registry_accepts_logger
  logger = Logger.new
  registry = CommandRegistry.new(logger: logger)

  # Registry ska spara loggern
  assert_equal logger, registry.logger
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Uppdatera CommandRegistry

**Din uppgift:** Uppdatera `lib/command_registry.rb`

**Vad ska ändras:**

1. **I `initialize`:**
   - Lägg till `logger: nil` parameter (optional!)
   - Spara `@logger = logger`

2. **Lägg till:**
   - `attr_reader :logger`

**Kör testet** - det ska passa!

---

### Test 2: Registry Loggar När Hooks Triggas

Nu ska vi använda den injicerade loggern!

#### 🔴 RED - Skriv Testet

```ruby
def test_registry_logs_when_triggering_hooks
  logger = Logger.new
  registry = CommandRegistry.new(logger: logger)

  registry.trigger_before_hooks(:hello)

  assert_equal 1, logger.messages.length
  assert_match /hello/, logger.messages.first
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera Logging

**Din uppgift:** Uppdatera `trigger_before_hooks` och `trigger_after_hooks` i CommandRegistry

**Vad ska ändras:**

I `trigger_before_hooks`:
- Före du kör hooks, logga med `@logger.info("Executing: #{command_name}")` om `@logger` finns

I `trigger_after_hooks`:
- Efter hooks, logga med `@logger.info("Completed: #{command_name}")`

**Hantera optional logger:**

Eftersom `@logger` kan vara `nil`, måste vi kolla innan vi anropar metoder:

```ruby
# Alternativ 1: if-villkor
@logger.info(message) if @logger

# Alternativ 2: Safe navigation operator (rekommenderat)
@logger&.info(message)
```

**Vad gör `&.`?**
- Kallas "safe navigation operator" eller "lonely operator"
- Om `@logger` är `nil`, returneras `nil` (inget anrop görs)
- Om `@logger` finns, anropas `.info(message)` normalt
- Kortare och tydligare än `if @logger`

**Kör testet** - det ska passa!

---

## Del 3: Ta Bort Hook-Baserad Logging

Nu när vi har logger injection behöver vi inte längre hårdkodade hooks för loggning!

### Uppdatera bot.rb

**Din uppgift:** Öppna `bot.rb` och gör följande ändringar:

1. **Lägg till require:**
```ruby
require_relative 'lib/logger'
```

2. **Skapa logger:**
```ruby
# Skapa logger
logger = Logger.new
```

3. **Injicera logger i registry:**
```ruby
# Skapa registry MED logger
registry = CommandRegistry.new(logger: logger)
```

4. **Ta bort de gamla hooks:**
```ruby
# ❌ TA BORT dessa rader:
registry.before_execute do |command_name|
  puts "▶️  Running: !#{command_name}"
end

registry.after_execute do |command_name|
  puts "✅ Done: !#{command_name}"
end
```

5. **Hooks triggas fortfarande i message handler** - men nu använder de den injicerade loggern internt!

### Testa!

```bash
ruby bot.rb
```

När du kör kommandon i Discord ska du nu se logger-output:
```
INFO: Executing: hello
INFO: Completed: hello
```

---

## Del 4: FileLogger - Polymorfism med DI

Nu ska vi se den riktiga styrkan med DI - att kunna byta implementation utan att ändra CommandRegistry!

### Konceptet: Same Interface, Different Implementation

Med DI kan vi skapa olika logger-implementationer som alla har samma interface:

```ruby
# Båda har .info(), .warn(), .error()
terminal_logger = Logger.new
file_logger = FileLogger.new("bot.log")

# CommandRegistry bryr sig inte om vilken!
registry = CommandRegistry.new(logger: terminal_logger)
# eller
registry = CommandRegistry.new(logger: file_logger)
```

CommandRegistry behöver inte ändras - den fungerar med båda!

### Test 1: FileLogger Skriver till Fil

#### 🔴 RED - Skriv Testet

Skapa `test/test_file_logger.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/file_logger'

class TestFileLogger < Minitest::Test
  def setup
    @log_file = "test.log"
    File.delete(@log_file) if File.exist?(@log_file)
  end

  def teardown
    File.delete(@log_file) if File.exist?(@log_file)
  end

  def test_file_logger_writes_to_file
    logger = FileLogger.new(@log_file)
    logger.info("Test message")

    assert File.exist?(@log_file)
    contents = File.read(@log_file)
    assert_match /INFO: Test message/, contents
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera FileLogger

**Din uppgift:** Skapa `lib/file_logger.rb`

**Vad behöver den?**
- `initialize(filename)` - Spara `@filename = filename`
- `info(message)`, `warn(message)`, `error(message)` - Samma interface som Logger!
- Skriv till fil istället för puts

**Tips för filskrivning:**
```ruby
def info(message)
  File.open(@filename, 'a') do |file|
    file.puts "INFO: #{message}"
  end
end
```

**`'a'` betyder "append mode"** - lägger till i slutet av filen istället för att skriva över.

**Kör testet** - det ska passa!

---

### Test 2: FileLogger med Flera Nivåer

**Din uppgift:** Lägg till test som verifierar att FileLogger kan logga alla nivåer:

```ruby
def test_file_logger_has_multiple_levels
  logger = FileLogger.new(@log_file)

  logger.info("Info message")
  logger.warn("Warning message")
  logger.error("Error message")

  contents = File.read(@log_file)
  assert_match /INFO: Info message/, contents
  assert_match /WARN: Warning message/, contents
  assert_match /ERROR: Error message/, contents
end
```

**Implementera** `warn` och `error` metoder.

**Kör testet** - det ska passa!

---

### Test 3: Registry Fungerar med FileLogger

Nu kommer magin - CommandRegistry ska fungera med FileLogger **utan några ändringar**!

#### 🔴 RED - Skriv Testet

Öppna `test/test_command_registry.rb` och lägg till:

```ruby
def setup
  @log_file = "test_registry.log"
  File.delete(@log_file) if File.exist?(@log_file)
end

def teardown
  File.delete(@log_file) if File.exist?(@log_file)
end

def test_registry_works_with_file_logger
  file_logger = FileLogger.new(@log_file)
  registry = CommandRegistry.new(logger: file_logger)

  registry.trigger_before_hooks(:hello)

  contents = File.read(@log_file)
  assert_match /hello/, contents
end
```

**Notera:** Om du redan har `setup`/`teardown` i test-filen, lägg bara till fil-cleaningen där!

**Kör testet** - det ska passa **direkt** om du implementerat rätt!

#### Vad Hände Här?

```ruby
# CommandRegistry.rb - INGEN ändring behövdes!
def trigger_before_hooks(command_name = nil)
  @logger&.info("Executing: #{command_name}")
  @before_hooks.each { |hook| hook.call(command_name) }
end
```

CommandRegistry anropar bara `.info(...)` - den vet inte om det är:
- `Logger` som använder `puts`
- `FileLogger` som skriver till fil
- Något helt annat i framtiden!

**Detta är polymorfism + dependency injection i praktiken!**

---

### Använd FileLogger i bot.rb (Valfritt)

Om du vill logga till fil istället för terminal:

```ruby
require_relative 'lib/file_logger'

# Använd FileLogger istället
logger = FileLogger.new("bot.log")
registry = CommandRegistry.new(logger: logger)
```

Nu loggas alla kommandon till `bot.log` istället för terminalen!

---

## Koncept: Varför är DI Bättre för Testning?

### Innan DI (Omöjligt att Testa)

```ruby
class CommandRegistry
  def trigger_before_hooks(name)
    puts "Running: #{name}"  # Hårdkodat puts - hur testar vi detta?
  end
end

# I test - kan inte verifiera att puts anropades!
def test_logs_execution
  registry = CommandRegistry.new
  registry.trigger_before_hooks(:test)
  # ??? Hur kontrollerar vi att det loggades?
end
```

### Efter DI (Lätt att Testa)

```ruby
class CommandRegistry
  def initialize(logger: nil)
    @logger = logger
  end

  def trigger_before_hooks(name)
    @logger&.info("Running: #{name}")
  end
end

# I test - kan verifiera genom att inspektera logger!
def test_logs_execution
  logger = Logger.new
  registry = CommandRegistry.new(logger: logger)

  registry.trigger_before_hooks(:test)

  assert_equal 1, logger.messages.length  # ✅ Testbart!
end
```

**DI gör kod testbar genom att:**
- Dependencies kan bytas ut mot mocks/stubs
- Vi kan inspektera vad dependencies gör
- Tester blir snabba (ingen fil I/O, databas, etc.)

---

## Del 5: Optional Dependencies

Inte alla klasser behöver en logger - använd optional parameters!

### Test: Registry Fungerar Utan Logger

```ruby
def test_registry_works_without_logger
  registry = CommandRegistry.new  # Ingen logger!
  hello = TextCommand.new(name: "hello", description: "Test", text: "Hi!")

  registry.register(hello)
  registry.trigger_before_hooks(:hello)  # Ska inte krascha

  assert_equal hello, registry.find(:hello)
end
```

**Detta ska redan fungera** om du använt `@logger&.info(...)` eller `@logger.info(...) if @logger`!

---

## Koncept: Constructor vs Setter Injection

Det finns två sätt att injicera dependencies:

### Constructor Injection (Rekommenderat)

```ruby
class CommandRegistry
  def initialize(logger: nil)
    @logger = logger  # Injiceras vid skapande
  end
end

registry = CommandRegistry.new(logger: logger)
```

**Fördelar:**
- ✅ Tydligt vilka dependencies som behövs
- ✅ Objekt är "complete" efter skapande
- ✅ Dependencies kan inte ändras efter skapande (immutability)

### Setter Injection

```ruby
class CommandRegistry
  attr_writer :logger

  def initialize
    @logger = nil
  end
end

registry = CommandRegistry.new
registry.logger = Logger.new  # Injiceras efter skapande
```

**Fördelar:**
- Optional dependencies kan läggas till senare
- Mer flexibelt

**Nackdelar:**
- Dependencies kan glömmas bort
- Objekt kan vara i "incomplete" state

**Använd constructor injection som standard!**

---

## Vanliga Misstag

### 1. Glömma Kolla om Dependency Finns

```ruby
# ❌ FEL - Kraschar om ingen logger injicerats
def trigger_before_hooks(name)
  @logger.info("Running: #{name}")  # NoMethodError om @logger är nil!
end

# ✅ RÄTT - Kolla först
def trigger_before_hooks(name)
  @logger&.info("Running: #{name}")  # Safe navigation
  # eller
  @logger.info("Running: #{name}") if @logger
end
```

### 2. Skapa Dependencies Inne i Klassen

```ruby
# ❌ FEL - Skapar logger internt (inte DI!)
class CommandRegistry
  def initialize(logger: nil)
    @logger = logger || Logger.new  # Skapar fallback
  end
end

# ✅ RÄTT - Låt anroparen bestämma
class CommandRegistry
  def initialize(logger: nil)
    @logger = logger  # Bara spara, skapa inte
  end
end

# Anropare skapar och injicerar
logger = Logger.new
registry = CommandRegistry.new(logger: logger)
```

### 3. Injicera För Många Dependencies

```ruby
# ❌ FEL - För många dependencies = design smell
class CommandRegistry
  def initialize(logger: nil, database: nil, cache: nil, notifier: nil, analytics: nil)
    # ...
  end
end

# ✅ RÄTT - Om du har många dependencies, kanske klassen gör för mycket?
# Överväg att dela upp i mindre klasser!
```

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är Dependency Injection?**
   - Svar: Skicka in dependencies till en klass istället för att skapa dem internt. Gör kod testbar och flexibel.

2. **Varför gör DI kod mer testbar?**
   - Svar: Dependencies kan bytas ut mot mocks i tester, så vi kan verifiera beteende utan external dependencies.

3. **När ska du använda optional dependencies (logger: nil)?**
   - Svar: När dependency inte är kritisk för klassen att fungera. Logger, analytics, etc.

4. **Vad är skillnaden mellan constructor och setter injection?**
   - Svar: Constructor injection sker vid skapande (tydligare), setter injection sker efter (mer flexibelt).

5. **Hur kollar du om en optional dependency finns?**
   - Svar: `@dependency&.method(...)` eller `@dependency.method(...) if @dependency`

6. **Varför fungerar FileLogger med CommandRegistry utan att ändra någon kod?**
   - Svar: Polymorfism - båda loggers har samma interface (info, warn, error). CommandRegistry bryr sig bara om interfacet, inte implementationen.

7. **Vad är "tight coupling" och varför är det dåligt?**
   - Svar: När en klass är hårt kopplad till en annan (känner till klassnamn, skapar instanser). Svårt att testa, ändra och återanvända.

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **Log Levels** - Filtrera meddelanden baserat på nivå
- **Null Logger** - Null Object Pattern för tester
- **Dependency Injection Container** - Automatisk dependency management
- **Inject Bot into Commands** - Commands kan skicka custom meddelanden
- **Composite Logger** - Logga till flera platser samtidigt
- **Och mer...**

---

## Nästa Steg

I **Uppgift 8 (SOLID Principles)** kommer vi lära oss:
- **Single Responsibility Principle** - En klass, ett ansvar
- **Open/Closed Principle** - Öppen för utökning, stängd för modifiering
- **Liskov Substitution Principle** - Subklasser ska kunna ersätta basklasser
- **Interface Segregation Principle** - Små, specifika interfaces
- **Dependency Inversion Principle** - Beroende på abstraktioner, inte konkreta klasser

**Grattis!** Du har lärt dig Dependency Injection - ett fundamentalt designmönster! 🎉

## Resurser

- [Dependency Injection Explained](https://www.rubyguides.com/2018/11/dependency-injection/)
- [Why Dependency Injection?](https://thoughtbot.com/blog/dependency-injection-in-ruby)
- [Testing with DI](https://www.sitepoint.com/dependency-injection-ruby/)
- [SOLID Principles Overview](https://medium.com/rubyinside/s-o-l-i-d-the-first-5-principles-of-object-oriented-design-with-ruby-examples-fc2ac3b34b9)
