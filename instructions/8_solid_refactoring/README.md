# Uppgift 8: SOLID - Refaktorering (SRP & OCP)

## Översikt

I denna uppgift börjar du lära dig **SOLID** - fem designprinciper som hjälper dig skriva bättre objektorienterad kod. Du kommer fokusera på de två första principerna genom att refaktorera din befintliga kod med TDD.

## Förutsättningar

- ✅ Uppgift 7 klar (Dependency Injection)
- ✅ Din `my_discord_bot/` mapp med CommandRegistry, Logger, och FileLogger

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara Single Responsibility Principle (SRP)
- Förklara Open/Closed Principle (OCP)
- Identifiera när kod bryter mot SRP och OCP
- Refaktorera kod för att följa SRP och OCP
- Använda TDD för säker refaktorering

---

## Vad är SOLID?

**SOLID** är en akronym för fem designprinciper skapade av Robert C. Martin (Uncle Bob):

- **S** - Single Responsibility Principle (SRP) ← Vi fokuserar på denna!
- **O** - Open/Closed Principle (OCP) ← Och denna!
- **L** - Liskov Substitution Principle (LSP)
- **I** - Interface Segregation Principle (ISP)
- **D** - Dependency Inversion Principle (DIP)

**Varför SOLID?**
- ✅ Lättare att förstå och underhålla
- ✅ Enklare att testa
- ✅ Mer flexibel kod
- ✅ Färre buggar
- ✅ Lättare att utöka

**I denna uppgift:** Vi täcker S och O genom hands-on refaktorering.

**I Uppgift 9:** Vi täcker L, I och D genom verifiering och analys.

---

## S - Single Responsibility Principle

### Konceptet

**"En klass ska ha endast ett ansvar (en anledning att ändras)"**

**Exempel på brott:**
```ruby
class User
  def save_to_database; end    # Ansvar 1: Persistens
  def send_welcome_email; end  # Ansvar 2: Kommunikation
  def validate_email; end      # Ansvar 3: Validering
end
```

Om vi ändrar databas-teknologi måste vi ändra User-klassen!

**Refaktorerad:**
```ruby
class User; end                 # Data
class UserRepository; end       # Persistens
class UserMailer; end           # Kommunikation
```

Nu har varje klass ETT ansvar!

---

## Del 1: Identifiera SRP-Brott i Vår Bot

Låt oss titta på din nuvarande `CommandRegistry`:

```ruby
class CommandRegistry
  def initialize(logger: nil)
    @commands = {}
    @logger = logger
    @before_hooks = []
    @after_hooks = []
  end

  def register(command)
    # ...
  end

  def find(name)
    # ...
  end

  def before_execute(&block)
    @before_hooks << block
  end

  def after_execute(&block)
    @after_hooks << block
  end

  def trigger_before_hooks(name)
    @logger&.info("Executing: #{name}")
    @before_hooks.each { |hook| hook.call(name) }
  end

  # ... mer kod
end
```

**Fråga:** Hur många ansvarsområden har CommandRegistry?

**Svar:**
1. ✅ Hantera kommando-registrering (register, find)
2. ❌ Hantera hooks (before_execute, after_execute, trigger)

**Logging är OK** - det är en injicerad dependency, inte ett ansvar för CommandRegistry.

**Men hooks är ett separat ansvar!** Vi ska extrahera det till en egen klass.

---

### Test 1: Skapa HookManager

#### 🔴 RED - Skriv Testet

Skapa `test/test_hook_manager.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/hook_manager'

class TestHookManager < Minitest::Test
  def test_hook_manager_can_register_before_hooks
    manager = HookManager.new
    hook_called = false

    manager.before { hook_called = true }
    manager.trigger_before

    assert hook_called
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera HookManager

**Din uppgift:** Skapa `lib/hook_manager.rb`

**Vad behövs:**
- `initialize` - Skapa `@before_hooks = []` och `@after_hooks = []`
- `before(&block)` - Lägg till block i `@before_hooks`
- `after(&block)` - Lägg till block i `@after_hooks`
- `trigger_before(args = nil)` - Kör alla before hooks med `.call(args)` om args finns
- `trigger_after(args = nil)` - Kör alla after hooks

**Kör testet** - det ska passa!

---

### Test 2: HookManager med Parametrar

**Din uppgift:** Lägg till test som verifierar att hooks kan ta emot parametrar:

```ruby
def test_hooks_receive_parameters
  manager = HookManager.new
  received = nil

  manager.before { |param| received = param }
  manager.trigger_before(:test)

  assert_equal :test, received
end
```

**Implementera** stöd för parametrar i trigger-metoderna.

**Kör testet** - det ska passa!

---

### Test 3: HookManager med Flera Hooks

**Din uppgift:** Lägg till test som verifierar att flera hooks kan registreras och körs i ordning:

```ruby
def test_multiple_hooks_execute_in_order
  manager = HookManager.new
  results = []

  manager.before { results << "first" }
  manager.before { results << "second" }
  manager.trigger_before

  assert_equal ["first", "second"], results
end
```

**Kör testet** - det ska passa om din implementation är korrekt!

---

## Del 2: Refaktorera CommandRegistry

Nu ska vi använda HookManager i CommandRegistry istället för att hantera hooks själv.

### Test 1: Registry Använder HookManager

#### 🔴 RED - Uppdatera Testet

Öppna `test/test_command_registry.rb` och lägg till:

```ruby
def test_registry_uses_hook_manager
  logger = Logger.new
  hook_manager = HookManager.new
  registry = CommandRegistry.new(logger: logger, hook_manager: hook_manager)

  assert_equal hook_manager, registry.hook_manager
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Refaktorera

**Din uppgift:** Uppdatera `CommandRegistry`

**Vad ska ändras:**

1. **I `initialize`:**
   - Lägg till `hook_manager: nil` parameter
   - Spara `@hook_manager = hook_manager || HookManager.new`
   - **Ta bort** `@before_hooks = []` och `@after_hooks = []`

2. **Ta bort metoder:**
   - Ta bort `before_execute(&block)`
   - Ta bort `after_execute(&block)`
   - Ta bort `trigger_before_hooks(command_name)`
   - Ta bort `trigger_after_hooks(command_name)`

3. **Lägg till:**
   - `attr_reader :hook_manager`

**Kör testet** - det ska passa!

---

### Test 2: Registry med Injicerad HookManager

Låt oss verifiera att vi kan injicera en HookManager och använda den:

```ruby
def test_registry_triggers_hooks_via_hook_manager
  logger = ArrayLogger.new
  hook_manager = HookManager.new
  registry = CommandRegistry.new(logger: logger, hook_manager: hook_manager)

  # Registrera en hook som använder loggern
  hook_manager.before { |name| logger.info("Before: #{name}") }

  # Trigga hooken
  hook_manager.trigger_before(:test)

  assert_equal 1, logger.messages.length
  assert_match /Before: test/, logger.messages.first
end
```

**Kör testet** - det ska passa!

---

## Del 3: Uppdatera bot.rb

Nu behöver vi uppdatera `bot.rb` för att använda den nya arkitekturen.

**Din uppgift:** Uppdatera `bot.rb`

**Lägg till require:**
```ruby
require_relative 'lib/hook_manager'
```

**Skapa och konfigurera hook manager:**
```ruby
# Skapa logger
logger = Logger.new

# Skapa hook manager
hook_manager = HookManager.new

# Registrera hooks som använder loggern
hook_manager.before do |command_name|
  logger.info("Executing: #{command_name}")
end

hook_manager.after do |command_name|
  logger.info("Completed: #{command_name}")
end

# Skapa registry med injicerade dependencies
registry = CommandRegistry.new(logger: logger, hook_manager: hook_manager)
```

**I message handler:**
```ruby
command = registry.find(command_name)

if command
  # Trigga before hook
  normalized_name = command_name.to_s.downcase.gsub(/^!/, '').to_sym
  registry.hook_manager.trigger_before(normalized_name)

  # Kör kommandot
  if command.is_a?(RollCommand)
    command.execute(event, args)
  else
    command.execute(event)
  end

  # Trigga after hook
  registry.hook_manager.trigger_after(normalized_name)
end
```

**Testa:**
```bash
ruby bot.rb
```

Boten ska fungera exakt som innan - men nu har CommandRegistry BARA ett ansvar!

---

## 🎉 SRP Uppnått!

**Före:** CommandRegistry hade två ansvarsområden (kommandon + hooks)
**Efter:** Varje klass har ett ansvar (CommandRegistry = kommandon, HookManager = hooks)

**Fördelar:** Lättare att testa, förstå, ändra och återanvända.

---

## O - Open/Closed Principle

### Konceptet

**"Klasser ska vara öppna för utökning men stängda för modifiering"**

Du ska kunna lägga till ny funktionalitet **utan att ändra existerande kod**.

**Exempel på brott:**
```ruby
class ReportGenerator
  def generate(type)
    case type
    when :pdf then generate_pdf
    when :html then generate_html
    when :csv then generate_csv  # Måste ändra varje gång!
    end
  end
end
```

**Refaktorerad (med DI + polymorfism):**
```ruby
class ReportGenerator
  def initialize(formatter)
    @formatter = formatter  # Injicera formattern
  end

  def generate(data)
    @formatter.format(data)  # Ingen case-statement!
  end
end

# Nya formatters utan att ändra ReportGenerator
generator = ReportGenerator.new(PDFFormatter.new)
generator = ReportGenerator.new(HTMLFormatter.new)
```

Nu kan vi lägga till nya formatters **utan att ändra** `ReportGenerator`!

---

## Del 4: OCP i Praktiken

Tack vare Dependency Injection (Uppgift 7) följer vi redan OCP!

**Vi har redan:**
- Logger (terminal)
- FileLogger (fil)

CommandRegistry är **stängd för modifiering** - vi kan lägga till nya logger-typer utan att ändra den!

---

## Del 5: Bevisa OCP med ArrayLogger

Låt oss bevisa att vi kan lägga till en ny logger-typ utan att ändra CommandRegistry!

### Test 1: ArrayLogger Sparar Meddelanden

#### 🔴 RED - Skriv Testet

Skapa `test/test_array_logger.rb`:

```ruby
require_relative 'spec_helper'
require_relative '../lib/array_logger'

class TestArrayLogger < Minitest::Test
  def test_array_logger_stores_messages_in_array
    logger = ArrayLogger.new

    logger.info("Test 1")
    logger.warn("Test 2")

    assert_equal 2, logger.messages.length
    assert_equal "INFO: Test 1", logger.messages[0]
    assert_equal "WARN: Test 2", logger.messages[1]
  end
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera ArrayLogger

**Din uppgift:** Skapa `lib/array_logger.rb`

**Vad behövs:**
- Samma interface som `Logger` och `FileLogger` (info, warn, error)
- Spara meddelanden i `@messages` array (istället för puts eller fil)
- `attr_reader :messages`

**Varför är detta användbart?**
- Perfekt för tester! (kan inspektera vad som loggades)
- Ingen terminal-output eller fil I/O i tester

**Kör testet** - det ska passa!

---

### Test 2: ArrayLogger med Error-nivå

**Din uppgift:** Lägg till test för `error` metoden:

```ruby
def test_array_logger_logs_errors
  logger = ArrayLogger.new

  logger.error("Critical error!")

  assert_equal 1, logger.messages.length
  assert_equal "ERROR: Critical error!", logger.messages.first
end
```

**Implementera** `error` metoden.

**Kör testet** - det ska passa!

---

### Test 3: Registry Fungerar med ArrayLogger

Nu kommer beviset - kan vi använda ArrayLogger med CommandRegistry **utan att ändra CommandRegistry**?

**Din uppgift:** Lägg till test i `test/test_command_registry.rb`:

```ruby
def test_registry_works_with_array_logger
  logger = ArrayLogger.new
  hook_manager = HookManager.new
  registry = CommandRegistry.new(logger: logger, hook_manager: hook_manager)

  hook_manager.before { |name| logger.info("Before: #{name}") }
  hook_manager.trigger_before(:test)

  assert_equal 1, logger.messages.length
  assert_match /Before: test/, logger.messages.first
end
```

**Kör testet** - det ska passa **utan att ändra CommandRegistry**!

---

## 🎉 OCP Uppnått!

**Bevis:**
1. Vi skapade `Logger` (Uppgift 7)
2. Vi skapade `FileLogger` (Uppgift 7)
3. Vi skapade `ArrayLogger` (just nu)
4. CommandRegistry fungerar med ALLA tre **utan ändringar**!

**Detta bevisar OCP:**
- CommandRegistry är **öppen för utökning** (nya logger-typer)
- CommandRegistry är **stängd för modifiering** (behöver inte ändras)

**Hur uppnådde vi det?**
- Dependency Injection (logger injiceras)
- Polymorfism (alla loggers har samma interface)
- Duck Typing (Ruby bryr sig bara om att `.info()`, `.warn()`, `.error()` finns)

---

## Sammanfattning

I denna uppgift har du:

✅ **Lärt dig Single Responsibility Principle**
- Extraherade HookManager från CommandRegistry
- Varje klass har nu ett tydligt, fokuserat ansvar

✅ **Lärt dig Open/Closed Principle**
- Skapade ArrayLogger utan att ändra CommandRegistry
- Bevisade att din arkitektur är utökningsbar

✅ **Refaktorerat med TDD**
- Alla tester gröna före refaktorering
- Alla tester gröna efter refaktorering
- Nya tester för nya klasser

**I nästa uppgift (Uppgift 9):** Vi täcker de tre sista SOLID-principerna (LSP, ISP, DIP) genom att verifiera och analysera din arkitektur.

---

## Vanliga Misstag

### 1. Tro att SRP Betyder "En Metod Per Klass"

❌ Överdriven separation: `class UserFirstName` för bara `@first_name`
✅ Rimlig separation: `class User` med flera relaterade attribut

SRP betyder "ett ansvar", inte "en metod"!

### 2. Glömma TDD När Man Refaktorerar

❌ Ändra massa kod → Hoppas det fungerar
✅ Tester gröna → Refaktorera → Tester fortfarande gröna

Tester ger dig säkerhet att refaktorering inte förstörde något!

### 3. Skapa Abstraktioner För Tidigt

❌ Skapa `StringPrinter` klass för att bara göra `puts "hello"`
✅ KISS (Keep It Simple, Stupid) - använd `puts` direkt

Använd SOLID när det löser riktiga problem, inte "för principens skull"!

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är Single Responsibility Principle?**
   - Svar: En klass ska ha bara ett ansvar - en anledning att ändras.

2. **Varför är SRP viktigt?**
   - Svar: Gör klasser lättare att förstå, testa och underhålla. Ändringar påverkar färre delar av koden.

3. **Vad är Open/Closed Principle?**
   - Svar: Öppen för utökning (nya features), stängd för modifiering (ändra existerande kod).

4. **Hur uppnår man OCP?**
   - Svar: Dependency Injection + Polymorfism. Injicera dependencies med gemensamt interface.

5. **Varför extraherade vi HookManager?**
   - Svar: CommandRegistry hade två ansvarsområden. Nu har varje klass ett ansvar (SRP).

6. **Varför fungerar ArrayLogger med CommandRegistry?**
   - Svar: OCP + polymorfism. ArrayLogger har samma interface som Logger/FileLogger.

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **Plugin System med OCP** - Lägg till kommandon dynamiskt
- **Command Validator med SRP** - Separera validering från execution
- **Builder Pattern** - Renare bot-konfiguration
- **Och mer...**

---

## Nästa Steg

I **Uppgift 9 (SOLID - Verification)** kommer vi:
- **Liskov Substitution Principle** - Verifiera att subklasser kan ersätta basklasser
- **Interface Segregation Principle** - Analysera våra interfaces
- **Dependency Inversion Principle** - Verifiera att vi beror på abstraktioner
- **Sammanfattning** - Se hur hela boten följer alla SOLID-principer

**Grattis!** Du har refaktorerat din kod för att följa de två första SOLID-principerna! 🎉

## Resurser

- [SOLID Principles Explained](https://medium.com/rubyinside/s-o-l-i-d-the-first-5-principles-of-object-oriented-design-with-ruby-examples-fc2ac3b34b9)
- [Single Responsibility Principle](https://thoughtbot.com/blog/single-responsibility-principle)
- [Open/Closed Principle](https://thoughtbot.com/blog/back-to-basics-solid)
- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html)
