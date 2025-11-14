# Stretch Goals - Uppgift 8: SOLID Principles

Dessa är **valfria** utmaningar för dig som vill öva mer på SOLID-principer och avancerad OOP.

---

## 1. Plugin System med OCP

Skapa ett plugin-system där nya kommandon kan laddas dynamiskt utan att ändra huvudkoden!

### Konceptet

```ruby
# Lägg till nya kommandon genom att bara skapa filer i plugins/
# plugins/weather_command.rb
# plugins/joke_command.rb

# Bot laddar automatiskt alla plugins
loader = PluginLoader.new("plugins/")
loader.load_all.each do |command|
  registry.register(command)
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_plugin_loader_loads_commands_from_directory
  # Skapa temp directory med mock plugin
  Dir.mkdir("test_plugins") unless Dir.exist?("test_plugins")
  File.write("test_plugins/test_command.rb", <<~RUBY
    class TestPluginCommand < Command
      def initialize
        super(name: "testplugin", description: "Test")
      end

      def execute(event)
        event.respond("Plugin works!")
      end
    end
  RUBY
  )

  loader = PluginLoader.new("test_plugins/")
  commands = loader.load_all

  assert_equal 1, commands.length
  assert_instance_of TestPluginCommand, commands.first

  # Cleanup
  FileUtils.rm_rf("test_plugins")
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class PluginLoader
  def initialize(plugin_dir)
    @plugin_dir = plugin_dir
  end

  def load_all
    commands = []
    Dir.glob("#{@plugin_dir}/*.rb").each do |file|
      require_relative "../#{file}"
      # Hitta command-klass och instantiera
      # Tips: Object.const_get(class_name)
    end
    commands
  end
end
```

**OCP i praktiken:** Lägg till nya kommandon utan att röra bot-koden!

---

## 2. Command Validator med SRP

Separera validering från command execution!

### Konceptet

```ruby
# Nuvarande: Validering i kommandot
class RollCommand
  def execute(event, args = [])
    notation = args.first || "d6"
    match = notation.match(/^(\d+)?d(\d+)$/i)

    unless match  # Validering blandat med execution
      return event.respond("Invalid format!")
    end

    # ... rullning
  end
end

# Bättre: Separera validering
validator = CommandValidator.new
if validator.valid?(command, args)
  command.execute(event, args)
else
  event.respond(validator.error_message)
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_validator_validates_roll_command
  validator = CommandValidator.new
  roll_command = RollCommand.new

  assert validator.valid?(roll_command, ["d20"])
  refute validator.valid?(roll_command, ["potato"])
  assert_equal "Invalid dice notation", validator.error_message
end
```

**🟢 Implementera:**

**Vad behövs:**
- `CommandValidator` klass
- `valid?(command, args)` metod
- `error_message` för senaste valideringen
- Olika validerings-logik för olika command-typer

**SRP:** Command ansvarar för execution, Validator för validering!

---

## 3. Builder Pattern för Bot-Konfiguration

Gör bot-konfiguration renare med Builder Pattern!

### Konceptet

```ruby
# Nuvarande: Skapar allt manuellt i bot.rb
logger = Logger.new
hook_manager = HookManager.new
registry = CommandRegistry.new(logger: logger, hook_manager: hook_manager)
# ... massa kod

# Med Builder:
bot = BotBuilder.new
  .with_logger(Logger.new)
  .with_hook_manager(HookManager.new)
  .with_command_registry
  .build

bot.start!
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_bot_builder_creates_configured_bot
  builder = BotBuilder.new
  bot = builder
    .with_logger(ArrayLogger.new)
    .with_token("test_token")
    .build

  assert_instance_of Bot, bot
  assert_instance_of ArrayLogger, bot.logger
end
```

**🟢 Implementera:**

**Vad behövs:**
```ruby
class BotBuilder
  def initialize
    @config = {}
  end

  def with_logger(logger)
    @config[:logger] = logger
    self  # Returnera self för chaining!
  end

  def with_token(token)
    @config[:token] = token
    self
  end

  def build
    Bot.new(@config)
  end
end
```

**Fördelar:** Tydlig konfiguration, lätt att testa, flexibel!

---

## 4. Strategy Pattern för Command Execution

Använd Strategy Pattern för olika execution-strategier!

### Konceptet

```ruby
# Olika sätt att exekvera kommandon
class SyncExecutionStrategy
  def execute(command, event, args)
    command.execute(event, args)
  end
end

class AsyncExecutionStrategy
  def execute(command, event, args)
    Thread.new { command.execute(event, args) }
  end
end

class LoggedExecutionStrategy
  def initialize(logger)
    @logger = logger
  end

  def execute(command, event, args)
    @logger.info("Executing: #{command.name}")
    result = command.execute(event, args)
    @logger.info("Completed: #{command.name}")
    result
  end
end

# Användning
executor = CommandExecutor.new(LoggedExecutionStrategy.new(logger))
executor.run(command, event, args)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_logged_execution_strategy_logs_execution
  logger = ArrayLogger.new
  strategy = LoggedExecutionStrategy.new(logger)
  command = TextCommand.new(name: "test", description: "Test", text: "Hi")
  event = MockEvent.new

  strategy.execute(command, event, [])

  assert_equal 2, logger.messages.length
  assert_match /Executing: test/, logger.messages[0]
  assert_match /Completed: test/, logger.messages[1]
end
```

**OCP & DIP:** Lägg till nya strategier utan att ändra CommandExecutor!

---

## 5. Observer Pattern för Command Events

Implementera Observer Pattern för att reagera på command events!

### Konceptet

```ruby
# Observers lyssnar på command events
class CommandStatsObserver
  def initialize
    @command_count = {}
  end

  def on_command_executed(command_name)
    @command_count[command_name] ||= 0
    @command_count[command_name] += 1
  end

  def most_used_command
    @command_count.max_by { |_, count| count }&.first
  end
end

# Registry notifierar observers
registry.add_observer(CommandStatsObserver.new)
registry.add_observer(CommandLoggerObserver.new(logger))

# När kommando körs
registry.notify_observers(:command_executed, command_name)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_registry_notifies_observers
  observer = CommandStatsObserver.new
  registry = CommandRegistry.new
  registry.add_observer(observer)

  # Simulera command execution
  registry.notify_observers(:command_executed, :hello)
  registry.notify_observers(:command_executed, :hello)
  registry.notify_observers(:command_executed, :ping)

  assert_equal :hello, observer.most_used_command
end
```

**🟢 Implementera:**

**Vad behövs:**
- `add_observer(observer)` i CommandRegistry
- `notify_observers(event, data)` metod
- Observer-klasser med callbacks (on_command_executed, etc.)

**OCP:** Lägg till nya observers utan att ändra CommandRegistry!

---

## 6. Command Queue med SRP

Separera command queueing från execution!

### Konceptet

```ruby
# Queue för att hantera kommandon asynkront
class CommandQueue
  def initialize
    @queue = []
  end

  def enqueue(command, event, args)
    @queue << { command: command, event: event, args: args }
  end

  def process_next
    return if @queue.empty?

    item = @queue.shift
    item[:command].execute(item[:event], item[:args])
  end

  def size
    @queue.length
  end
end

# Användning
queue = CommandQueue.new
queue.enqueue(hello_command, event, [])
queue.enqueue(ping_command, event, [])

# Process i bakgrunden
Thread.new { queue.process_next while queue.size > 0 }
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_queue_processes_commands_in_order
  queue = CommandQueue.new
  results = []

  cmd1 = TextCommand.new(name: "first", description: "Test", text: "First!")
  cmd2 = TextCommand.new(name: "second", description: "Test", text: "Second!")

  event = MockEvent.new

  queue.enqueue(cmd1, event, [])
  queue.enqueue(cmd2, event, [])

  queue.process_next
  queue.process_next

  assert_equal "First!", event.responses[0]
  assert_equal "Second!", event.responses[1]
end
```

**SRP:** CommandQueue ansvarar för queueing, Commands för execution!

---

## 7. Composite Pattern för Command Groups

Gruppera kommandon med Composite Pattern!

### Konceptet

```ruby
# Ett kommando som kör flera kommandon
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
morning_routine = CompositeCommand.new("morning", [
  TextCommand.new(name: "greeting", description: "Greet", text: "Good morning!"),
  TextCommand.new(name: "weather", description: "Weather", text: "It's sunny!"),
  RollCommand.new
])

# Kör alla kommandon i gruppen
morning_routine.execute(event)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_composite_command_executes_all_commands
  event = MockEvent.new

  cmd1 = TextCommand.new(name: "one", description: "Test", text: "First")
  cmd2 = TextCommand.new(name: "two", description: "Test", text: "Second")

  composite = CompositeCommand.new("group", [cmd1, cmd2])
  composite.execute(event)

  assert_equal 2, event.responses.length
  assert_equal "First", event.responses[0]
  assert_equal "Second", event.responses[1]
end
```

**LSP:** CompositeCommand kan ersätta Command överallt!

---

## 8. Template Method Pattern för Command Execution

Använd Template Method för att standardisera command execution flow!

### Konceptet

```ruby
# Abstrakt basklass med template method
class TemplateCommand < Command
  def execute(event, args = [])
    return unless validate(args)

    before_execute(event)
    result = perform(event, args)
    after_execute(event, result)

    result
  end

  # Subklasser override:ar dessa
  def validate(args)
    true  # Default: alltid valid
  end

  def before_execute(event)
    # Hook för subklasser
  end

  def perform(event, args)
    raise NotImplementedError
  end

  def after_execute(event, result)
    # Hook för subklasser
  end
end

# Konkret implementation
class ValidatedTextCommand < TemplateCommand
  def initialize(name, description, text)
    super(name: name, description: description)
    @text = text
  end

  def validate(args)
    @text && !@text.empty?
  end

  def perform(event, args)
    event.respond(@text)
  end

  def after_execute(event, result)
    puts "Command executed successfully!"
  end
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_template_command_follows_execution_flow
  event = MockEvent.new
  command = ValidatedTextCommand.new("test", "Test", "Hello")

  command.execute(event)

  assert_equal "Hello", event.responses.first
end

def test_template_command_validates_before_execution
  event = MockEvent.new
  command = ValidatedTextCommand.new("test", "Test", "")  # Invalid!

  result = command.execute(event)

  assert_nil result
  assert_empty event.responses
end
```

**OCP & Template Method:** Definiera execution flow en gång, utöka med subklasser!

---

## Vilka Stretch Goals Tränar Vad?

- **Plugin System** - OCP, dynamic loading, extensibility
- **Command Validator** - SRP, separating concerns
- **Builder Pattern** - Fluent interfaces, configuration management
- **Strategy Pattern** - OCP, DIP, interchangeable algorithms
- **Observer Pattern** - OCP, event-driven architecture
- **Command Queue** - SRP, asynchronous processing
- **Composite Pattern** - LSP, recursive structures
- **Template Method** - OCP, reusable algorithms

Lycka till! 🎉
