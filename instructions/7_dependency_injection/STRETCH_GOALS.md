# Stretch Goals - Uppgift 7: Dependency Injection

Dessa är **valfria** utmaningar för dig som vill öva mer på Dependency Injection och relaterade patterns.

---

## 1. Log Levels med Filtering

Lägg till möjlighet att filtrera meddelanden baserat på nivå.

### Konceptet

```ruby
# Visa bara ERROR och WARN, inte INFO
logger = Logger.new(level: :warn)
logger.info("Debug info")    # Visas INTE
logger.warn("Warning!")      # Visas
logger.error("Error!")       # Visas
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_logger_filters_by_level
  logger = Logger.new(level: :warn)

  logger.info("Info message")
  logger.warn("Warning message")
  logger.error("Error message")

  # INFO ska inte sparas
  assert_equal 2, logger.messages.length
  refute logger.messages.any? { |m| m.include?("Info") }
end
```

**🟢 Implementera:**

**Vad behövs:**
- Level hierarchy: `INFO < WARN < ERROR`
- Constructor tar `level:` parameter (default `:info`)
- Innan loggning, kolla om meddelande-nivå >= logger-nivå
- Spara/visa bara om nivån är tillräckligt hög

**Tips:**
```ruby
LEVELS = { info: 0, warn: 1, error: 2 }

def info(message)
  log(:info, message)
end

def log(level, message)
  return if LEVELS[level] < LEVELS[@level]
  # ... logga meddelande
end
```

---

## 2. Null Logger (Null Object Pattern)

Skapa en NullLogger som inte gör något - användbart för tester!

### Konceptet

```ruby
# I produktion
registry = CommandRegistry.new(logger: Logger.new)

# I tester där vi inte bryr oss om logging
registry = CommandRegistry.new(logger: NullLogger.new)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_null_logger_does_nothing
  logger = NullLogger.new

  logger.info("Message")
  logger.warn("Warning")
  logger.error("Error")

  # Inget sparas, inga fel kastas
  assert_equal 0, logger.messages.length
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class NullLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def info(message); end
  def warn(message); end
  def error(message); end
end
```

**Null Object Pattern:** Istället för `if @logger`, använd NullLogger som "gör ingenting"-implementation!

---

## 3. Inject Bot into Commands

Låt kommandon få tillgång till bot-objektet via DI!

### Konceptet

**Nuvarande problem:**
```ruby
# Commands kan bara svara via event
def execute(event)
  event.respond("Hello!")
end
```

**Med injicerad bot:**
```ruby
# Commands kan göra mer avancerade saker
def execute(event)
  @bot.send_message(channel_id, "Hello!")
  @bot.add_reaction(event.message, "👍")
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_can_use_injected_bot
  mock_bot = MockBot.new
  command = TextCommand.new(
    name: "hello",
    description: "Test",
    text: "Hello!",
    bot: mock_bot
  )

  mock_event = MockEvent.new
  command.execute(mock_event)

  # Verifiera att bot användes
  assert mock_bot.reaction_added?
end
```

**🟢 Implementera:**

**Vad behövs:**
- Uppdatera `TextCommand` constructor: `bot: nil`
- Spara `@bot = bot`
- MockBot klass för tester med metoder som `add_reaction`, `send_message`
- Använd bot i execute om den finns

---

## 4. Dependency Injection Container

Skapa en DI Container som hanterar skapande och injektion av dependencies!

### Konceptet

```ruby
# Manuell DI (nuvarande)
logger = Logger.new
registry = CommandRegistry.new(logger: logger)

# DI Container
container = DIContainer.new
container.register(:logger, Logger.new)
container.register(:registry) { |c| CommandRegistry.new(logger: c.resolve(:logger)) }

registry = container.resolve(:registry)  # Får automatiskt logger!
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_container_resolves_dependencies
  container = DIContainer.new
  container.register(:logger, Logger.new)

  logger = container.resolve(:logger)

  assert_instance_of Logger, logger
end

def test_container_resolves_nested_dependencies
  container = DIContainer.new
  container.register(:logger, Logger.new)
  container.register(:registry) do |c|
    CommandRegistry.new(logger: c.resolve(:logger))
  end

  registry = container.resolve(:registry)

  assert_instance_of CommandRegistry, registry
  assert_instance_of Logger, registry.logger
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class DIContainer
  def initialize
    @services = {}
  end

  def register(name, instance = nil, &block)
    @services[name] = instance || block
  end

  def resolve(name)
    service = @services[name]
    return service unless service.is_a?(Proc)
    service.call(self)  # Skicka container för nested resolution
  end
end
```

**Avancerad:** Lägg till singleton support (samma instans returneras varje gång)!

---

## 5. Configuration Object Injection

Injicera ett config-objekt istället för många parametrar!

### Konceptet

```ruby
# Många parametrar (dåligt)
registry = CommandRegistry.new(
  logger: logger,
  max_commands: 100,
  allow_duplicates: false,
  prefix: "!"
)

# Config object (bra)
config = BotConfig.new
config.logger = logger
config.max_commands = 100
config.prefix = "!"

registry = CommandRegistry.new(config: config)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_registry_uses_config_object
  config = BotConfig.new
  config.logger = Logger.new
  config.prefix = "/"

  registry = CommandRegistry.new(config: config)

  assert_equal config.logger, registry.logger
  assert_equal "/", registry.prefix
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class BotConfig
  attr_accessor :logger, :max_commands, :prefix, :allow_duplicates

  def initialize
    @max_commands = 100
    @prefix = "!"
    @allow_duplicates = false
  end
end
```

**Uppdatera CommandRegistry:**
- Ta emot `config:` parameter
- Extrahera värden från config: `@logger = config.logger`

---

## 6. Logger med Timestamps

Lägg till timestamps till alla log-meddelanden!

### Konceptet

```ruby
logger = Logger.new
logger.info("Test")
# Output: [2024-01-13 14:23:45] INFO: Test
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_logger_adds_timestamps
  logger = Logger.new
  logger.info("Test message")

  message = logger.messages.first
  assert_match /\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] INFO: Test message/, message
end
```

**🟢 Implementera:**

**Vad behövs:**
- Använd `Time.now.strftime("%Y-%m-%d %H:%M:%S")`
- Format: `"[#{timestamp}] #{level}: #{message}"`

---

## 7. Composite Logger (Logga till Flera Platser)

Skapa en logger som loggar till flera destinationer samtidigt!

### Konceptet

```ruby
# Logga till BÅDE terminal OCH fil
terminal_logger = Logger.new
file_logger = FileLogger.new("bot.log")
composite = CompositeLogger.new([terminal_logger, file_logger])

registry = CommandRegistry.new(logger: composite)
# Nu loggas till båda!
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_composite_logger_logs_to_multiple_loggers
  logger1 = Logger.new
  logger2 = Logger.new
  composite = CompositeLogger.new([logger1, logger2])

  composite.info("Test")

  assert_equal 1, logger1.messages.length
  assert_equal 1, logger2.messages.length
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class CompositeLogger
  def initialize(loggers)
    @loggers = loggers
  end

  def info(message)
    @loggers.each { |logger| logger.info(message) }
  end

  # Samma för warn, error
end
```

**Pattern:** Composite pattern - behandla flera objekt som ett!

---

## Vilka Stretch Goals Tränar Vad?

- **Log Levels** - Filtering, hierarchy, control flow
- **Null Logger** - Null Object Pattern, eliminating nil checks
- **Inject Bot** - Practical DI, giving commands more capabilities
- **DI Container** - Advanced DI, automatic dependency resolution
- **Configuration Object** - Reducing parameter count, grouping related config
- **Timestamps** - String formatting, Time handling
- **Composite Logger** - Composite Pattern, multiple destinations

Lycka till! 🎉
