# Stretch Goals - Uppgift 9: SOLID - Verification

Dessa är **valfria** utmaningar för dig som vill fördjupa dig i SOLID-principer och designmönster.

---

## 1. SOLID Violations Kata

Träna på att identifiera och fixa SOLID-brott i given kod!

### Konceptet

Du får kod som bryter mot SOLID-principer. Din uppgift är att:
1. Identifiera vilken/vilka principer som bryts
2. Förklara varför det är ett problem
3. Refaktorera koden med TDD

### Exempel: God Klass

```ruby
class GodClass
  def initialize
    @database = Database.new
    @email_service = EmailService.new
    @logger = Logger.new
  end

  def process_user(user_data)
    # Validering
    return false unless user_data[:email].include?("@")

    # Spara till databas
    @database.save("users", user_data)

    # Skicka välkomstmail
    @email_service.send(user_data[:email], "Welcome!")

    # Logga
    @logger.info("User processed: #{user_data[:name]}")

    true
  end
end
```

**Vilka SOLID-principer bryts?**
- **SRP:** GodClass har 4 ansvarsområden (validering, persistens, email, logging)
- **DIP:** Skapar dependencies internt istället för DI

**Din uppgift:** Refaktorera med TDD!

---

## 2. Design Patterns som Bygger på SOLID

Implementera klassiska designmönster som använder SOLID-principer!

### Strategy Pattern (OCP + DIP)

```ruby
# Olika sorteringsstrategier
class BubbleSortStrategy
  def sort(array)
    # Bubble sort implementation
  end
end

class QuickSortStrategy
  def sort(array)
    # Quick sort implementation
  end
end

# Sorter beror på abstraktion (OCP + DIP)
class Sorter
  def initialize(strategy)
    @strategy = strategy
  end

  def sort(array)
    @strategy.sort(array)
  end
end

# Användning
sorter = Sorter.new(QuickSortStrategy.new)
sorter.sort([3, 1, 2])
```

**Din uppgift:** Implementera med TDD, verifiera att det följer OCP och DIP!

---

## 3. Observer Pattern (OCP + ISP)

Implementera Observer Pattern för event-driven arkitektur!

### Konceptet

```ruby
class Subject
  def initialize
    @observers = []
  end

  def attach(observer)
    @observers << observer
  end

  def notify(event, data)
    @observers.each { |observer| observer.update(event, data) }
  end
end

class ConcreteObserver
  def update(event, data)
    puts "Received #{event}: #{data}"
  end
end

# Användning
subject = Subject.new
subject.attach(ConcreteObserver.new)
subject.notify(:user_created, { name: "Alice" })
```

**Din uppgift:**
- Implementera för din Discord-bot (command events)
- Verifiera OCP (kan lägga till observers utan att ändra Subject)
- Verifiera ISP (minimalt observer-interface)

---

## 4. Factory Pattern (SRP + OCP)

Skapa en Command Factory som följer SOLID!

### Konceptet

```ruby
class CommandFactory
  def create(type, **options)
    case type
    when :text
      TextCommand.new(**options)
    when :roll
      RollCommand.new
    when :embed
      EmbedCommand.new(**options)
    else
      raise "Unknown command type: #{type}"
    end
  end
end

# Användning
factory = CommandFactory.new
command = factory.create(:text, name: "hello", description: "Greet", text: "Hi!")
```

**Problem:** Bryter OCP (måste ändra factory för nya typer)

**Din uppgift:** Refaktorera till registry-based factory:

```ruby
class CommandFactory
  def initialize
    @builders = {}
  end

  def register(type, &builder)
    @builders[type] = builder
  end

  def create(type, **options)
    builder = @builders[type]
    raise "Unknown type: #{type}" unless builder
    builder.call(**options)
  end
end

# Setup
factory = CommandFactory.new
factory.register(:text) { |**opts| TextCommand.new(**opts) }
factory.register(:roll) { RollCommand.new }

# Användning
command = factory.create(:text, name: "hello", description: "Test", text: "Hi!")
```

Nu följer det OCP!

---

## 5. Null Object Pattern (LSP)

Implementera Null Object Pattern som perfekt exempel på LSP!

### Konceptet

```ruby
# Istället för nil-checks
class User
  def initialize(logger = nil)
    @logger = logger
  end

  def do_something
    @logger.info("Doing something") if @logger  # Måste kolla!
  end
end

# Använd Null Object
class NullLogger
  def info(message); end
  def warn(message); end
  def error(message); end
end

class User
  def initialize(logger = NullLogger.new)
    @logger = logger
  end

  def do_something
    @logger.info("Doing something")  # Ingen if-check behövs!
  end
end
```

**Din uppgift:**
- Implementera NullLogger för din bot
- Verifiera att den följer LSP (kan ersätta Logger)
- Använd i tester istället för `logger: nil`

---

## 6. Composite Pattern (LSP + OCP)

Skapa Command Groups med Composite Pattern!

### Konceptet

```ruby
class CompositeCommand < Command
  def initialize(name, commands)
    super(name: name, description: "Runs multiple commands")
    @commands = commands
  end

  def execute(event, args = [])
    @commands.each { |command| command.execute(event, args) }
  end
end

# Användning
morning = CompositeCommand.new("morning", [
  TextCommand.new(name: "greet", description: "Greet", text: "Good morning!"),
  RollCommand.new
])
```

**Din uppgift:**
- Implementera med TDD
- Verifiera LSP (CompositeCommand kan ersätta Command)
- Verifiera OCP (kan lägga till kommandon utan att ändra composite)

---

## 7. Decorator Pattern (OCP + SRP)

Lägg till funktionalitet till commands utan att ändra dem!

### Konceptet

```ruby
class LoggedCommand
  def initialize(command, logger)
    @command = command
    @logger = logger
  end

  def name
    @command.name
  end

  def description
    @command.description
  end

  def execute(event, args = [])
    @logger.info("Executing: #{name}")
    result = @command.execute(event, args)
    @logger.info("Completed: #{name}")
    result
  end
end

# Användning
command = TextCommand.new(name: "hello", description: "Greet", text: "Hi!")
logged_command = LoggedCommand.new(command, logger)
logged_command.execute(event)
```

**Din uppgift:**
- Implementera olika decorators (TimedCommand, ValidatedCommand)
- Verifiera OCP (lägger till funktionalitet utan att ändra originalkommandot)
- Verifiera SRP (varje decorator har ett ansvar)

---

## 8. SOLID Code Review Checklist

Skapa en checklist för att verifiera SOLID i kod!

### Checklist Template

**Single Responsibility:**
- [ ] Kan du beskriva klassens ansvar i EN mening?
- [ ] Finns det endast EN anledning till att ändra klassen?
- [ ] Har klassen mindre än ~150 rader kod?

**Open/Closed:**
- [ ] Kan ny funktionalitet läggas till utan att ändra klassen?
- [ ] Används dependency injection för flexibilitet?
- [ ] Finns det konkreta klasser hårdkodade i klassen?

**Liskov Substitution:**
- [ ] Kan subklasser ersätta basklassen utan fel?
- [ ] Kastar subklasser exceptions som basklassen inte gör?
- [ ] Fungerar alla tester med både basklass och subklasser?

**Interface Segregation:**
- [ ] Är interfacet minimalt (bara nödvändiga metoder)?
- [ ] Tvingas klasser implementera metoder de inte använder?
- [ ] Kan interfacet delas upp i mindre delar?

**Dependency Inversion:**
- [ ] Injiceras dependencies via constructor?
- [ ] Beror klassen på abstraktioner eller konkreta klasser?
- [ ] Kan dependencies bytas ut i tester?

**Din uppgift:** Använd denna checklist på din egen kod!

---

## 9. Refactoring Legacy Code

Träna på att refaktorera kod utan tester till SOLID-kod med tester!

### Process

1. **Add Characterization Tests** - Tester som beskriver nuvarande beteende
2. **Identify SOLID Violations** - Vilka principer bryts?
3. **Refactor One Principle at a Time** - Små steg
4. **Keep Tests Green** - Röd-Grön-Refaktorera

### Exempel: Legacy Bot Code

```ruby
# Legacy kod utan tester
class Bot
  def handle_message(message)
    if message.start_with?("!hello")
      puts "Hello!"
      File.open("bot.log", "a") { |f| f.puts "Hello command" }
    elsif message.start_with?("!roll")
      parts = message.split(" ")
      notation = parts[1] || "d6"
      # ... 50 rader med tärningsrullning
      File.open("bot.log", "a") { |f| f.puts "Roll command" }
    end
  end
end
```

**Din uppgift:**
1. Skriv characterization tests
2. Identifiera SOLID-brott
3. Refaktorera till din nya arkitektur
4. Verifiera att allt fungerar

---

## 10. SOLID Metrics

Mät hur "SOLID" din kod är!

### Metrics att Mäta

**Cyclomatic Complexity:**
- Antal decision points i en metod
- Lägre = bättre (följer SRP)

**Class Size:**
- Antal rader kod per klass
- < 150 rader = bra (SRP)

**Method Length:**
- Antal rader per metod
- < 10 rader = bra (SRP)

**Coupling:**
- Antal dependencies en klass har
- Färre = bättre (DIP)

**Cohesion:**
- Hur relaterade metoderna i en klass är
- Högre = bättre (SRP)

**Din uppgift:** Analysera din kod och förbättra metrics!

---

## Vilka Stretch Goals Tränar Vad?

- **SOLID Violations Kata** - Identifiera och fixa violations
- **Strategy Pattern** - OCP + DIP i praktiken
- **Observer Pattern** - Event-driven, OCP
- **Factory Pattern** - Registry-based, OCP
- **Null Object** - Perfekt LSP-exempel
- **Composite Pattern** - LSP + OCP
- **Decorator Pattern** - OCP + SRP
- **Code Review Checklist** - Systematisk SOLID-verifiering
- **Refactoring Legacy** - Praktisk SOLID-tillämpning
- **SOLID Metrics** - Kvantifiera kod-kvalitet

Lycka till! 🎉
