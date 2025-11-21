# Stretch Goals - Uppgift 6: Symbols & Blocks

Dessa är **valfria** utmaningar för dig som vill öva mer på symbols, blocks, och Ruby's funktionella features.

---

## 1. Lambda vs Proc vs Block

Förstå skillnaderna mellan Ruby's tre sätt att hantera "callable" kod.

### Konceptet

```ruby
# Block - kan inte sparas i variabel
[1, 2, 3].each { |n| puts n }

# Proc - kan sparas, flexibel return
my_proc = Proc.new { |n| puts n }
my_proc.call(5)

# Lambda - kan sparas, strikt return och argument-checking
my_lambda = lambda { |n| puts n }
my_lambda.call(5)

# Kort lambda-syntax
my_lambda = ->(n) { puts n }
```

### Skillnader

| Feature | Block | Proc | Lambda |
|---------|-------|------|--------|
| Kan sparas i variabel | ❌ | ✅ | ✅ |
| Return beteende | N/A | Returnerar från metoden som skapade den | Returnerar från lambdan |
| Argument checking | Nej | Flexibelt | Strikt (måste matcha) |

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_proc_vs_lambda_arguments
  my_proc = Proc.new { |a, b| a + b }
  my_lambda = lambda { |a, b| a + b }

  # Proc: flexibelt med argument
  assert_equal 3, my_proc.call(1, 2)
  assert_equal 1, my_proc.call(1)  # b blir nil, 1 + nil = 1 i Ruby? Nej...

  # Lambda: strikt med argument
  assert_equal 3, my_lambda.call(1, 2)
  assert_raises(ArgumentError) { my_lambda.call(1) }  # Kräver exakt 2 argument
end

def test_proc_vs_lambda_return
  def test_proc_return
    my_proc = Proc.new { return "from proc" }
    my_proc.call
    return "from method"
  end

  def test_lambda_return
    my_lambda = lambda { return "from lambda" }
    my_lambda.call
    return "from method"
  end

  assert_equal "from proc", test_proc_return  # Proc returnerar från metoden!
  assert_equal "from method", test_lambda_return  # Lambda returnerar bara från sig själv
end
```

### När Använda Vad?

- **Blocks**: Iteration, callbacks (yield)
- **Procs**: När du behöver flexibilitet med argument
- **Lambdas**: När du vill ha metod-liknande beteende med strict argument checking

---

## 2. Hooks med Error Handling

Vad händer om en hook kraschar? Låt oss hantera fel utan att stoppa hela programmet.

### Konceptet

```ruby
registry.before_execute do |name|
  raise "Something went wrong!"  # Vad händer nu?
end

# Utan error handling: hela programmet kraschar
# Med error handling: logga felet, fortsätt
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_hook_errors_dont_crash_program
  registry = CommandRegistry.new

  # Hook som kraschar
  registry.before_execute do
    raise "Hook error!"
  end

  # Hook som fungerar
  hook_called = false
  registry.before_execute do
    hook_called = true
  end

  # Triggers ska inte krascha även om första hooken failar
  registry.trigger_before_hooks(:test)

  # Andra hooken ska fortfarande ha körts
  assert hook_called
end
```

**🟢 Implementera:**

**Vad behövs:**
- Wrappa hook.call i begin/rescue
- Logga errors istället för att låta dem propagera
- Fortsätt köra andra hooks

**Tips:**
```ruby
def trigger_before_hooks(command_name = nil)
  @before_hooks.each do |hook|
    begin
      hook.call(command_name) if command_name
      hook.call unless command_name
    rescue => e
      # Logga error istället för att krascha
      puts "⚠️  Hook error: #{e.message}"
    end
  end
end
```

---

## 3. Method Objects

Ruby låter dig konvertera metoder till objekt som kan skickas runt!

### Konceptet

```ruby
class Greeter
  def hello(name)
    "Hello, #{name}!"
  end
end

greeter = Greeter.new

# Hämta metoden som objekt
method_object = greeter.method(:hello)

# Anropa den senare
method_object.call("Alice")  # => "Hello, Alice!"

# Skicka den som callback
["Alice", "Bob"].map(&method_object)  # => ["Hello, Alice!", "Hello, Bob!"]
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_execute_as_method_object
  command = TextCommand.new(name: "test", description: "Test", text: "Test!")
  mock_event = MockEvent.new

  # Hämta execute-metoden som objekt
  execute_method = command.method(:execute)

  # Anropa den
  execute_method.call(mock_event)

  assert_equal "Test!", mock_event.responses.first
end

def test_can_map_method_over_events
  command = TextCommand.new(name: "test", description: "Test", text: "Test!")

  events = [MockEvent.new, MockEvent.new, MockEvent.new]

  # Använd method object med map
  events.map(&command.method(:execute))

  events.each do |event|
    assert_equal "Test!", event.responses.first
  end
end
```

**Utmaning:** Använd method objects för att skapa en "command queue" som kör flera kommandon sekventiellt!

---

## 4. Configurable Registry med Block

Använd blocks för att konfigurera CommandRegistry vid skapande!

### Konceptet

```ruby
registry = CommandRegistry.new do |config|
  config.enable_logging = true
  config.enable_stats = true
  config.max_hooks = 10
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_can_configure_registry_with_block
  registry = CommandRegistry.new do |config|
    config.enable_logging = true
  end

  assert registry.logging_enabled?
end
```

**🟢 Implementera:**

**Vad behövs:**
- Config klass eller struct
- Initialize tar emot optional block
- Yield config object till blocket

**Tips:**
```ruby
class CommandRegistry
  attr_reader :config

  def initialize
    @config = Config.new
    yield(@config) if block_given?
    @commands = {}
    # ...
  end

  def logging_enabled?
    @config.enable_logging
  end

  class Config
    attr_accessor :enable_logging, :enable_stats, :max_hooks

    def initialize
      @enable_logging = false
      @enable_stats = false
      @max_hooks = Float::INFINITY
    end
  end
end
```

---

## 5. Symbol to_proc Magic

Du har sett `&:upcase` - förstå hur det fungerar!

### Konceptet

```ruby
# Vanlig map med block
["hello", "world"].map { |word| word.upcase }

# Symbol to_proc magic!
["hello", "world"].map(&:upcase)
```

**Hur fungerar det?**
- `&` försöker konvertera argument till block
- `:upcase` är en symbol
- Symbol#to_proc konverterar symbolen till en Proc
- Procen anropar metoden med samma namn

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_symbol_to_proc_with_command_names
  registry = CommandRegistry.new
  hello = TextCommand.new(name: "hello", description: "Test", text: "Hi!")
  world = TextCommand.new(name: "world", description: "Test", text: "World!")

  registry.register(hello)
  registry.register(world)

  # Hämta alla command names med symbol to_proc
  names = registry.all.map(&:name)

  assert_equal ["hello", "world"], names.sort
end
```

**Utmaning:** Implementera din egen `to_proc` på en custom klass!

```ruby
class CommandWrapper
  def initialize(command)
    @command = command
  end

  def to_proc
    # Din implementation här
    # Ska returnera en Proc som anropar @command.execute
  end
end

# Användning:
wrapper = CommandWrapper.new(hello_command)
[event1, event2].each(&wrapper)  # Kör hello_command.execute på varje event
```

---

## 6. Chainable Hooks

Gör så hooks kan kedjas som ActiveRecord scopes!

### Konceptet

```ruby
registry
  .before_execute { puts "Hook 1" }
  .before_execute { puts "Hook 2" }
  .after_execute { puts "Done!" }
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_hooks_are_chainable
  registry = CommandRegistry.new

  result = registry
    .before_execute { puts "1" }
    .before_execute { puts "2" }

  assert_instance_of CommandRegistry, result
end
```

**🟢 Implementera:**

**Vad behövs:**
- `before_execute` och `after_execute` returnerar `self`

**Tips:**
```ruby
def before_execute(&block)
  @before_hooks << block
  self  # Returnera registry för chaining!
end
```

---

## 7. Memoization med Blocks

Använd blocks för att lazy-initialize data.

### Konceptet

```ruby
class CommandRegistry
  def stats
    @stats ||= calculate_stats { |command|
      # Block för att konfigurera hur stats räknas
    }
  end
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_stats_are_memoized
  registry = CommandRegistry.new

  stats1 = registry.stats
  stats2 = registry.stats

  # Samma objekt (memoized)
  assert_equal stats1.object_id, stats2.object_id
end

def test_stats_can_be_configured_with_block
  registry = CommandRegistry.new

  stats = registry.stats do |command|
    # Custom stats logic
  end

  refute_nil stats
end
```

**🟢 Implementera:**

**Vad behövs:**
- Lazy initialization med `||=`
- Optional block för konfiguration
- Cacha resultatet

---

## 8. Timing Hooks

Mät hur lång tid kommandon tar att köra!

### Konceptet

```ruby
registry.before_execute do |name|
  @start_time = Time.now
end

registry.after_execute do |name|
  duration = Time.now - @start_time
  puts "Command #{name} took #{duration}s"
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_can_measure_command_execution_time
  registry = CommandRegistry.new
  timings = {}

  registry.before_execute do |name|
    timings[name] = Time.now
  end

  registry.after_execute do |name|
    timings[name] = Time.now - timings[name]
  end

  registry.trigger_before_hooks(:test)
  sleep(0.1)  # Simulera långsamt kommando
  registry.trigger_after_hooks(:test)

  assert timings[:test] >= 0.1
end
```

**Utmaning:** Skapa en `TimingRegistry` subklass som automatiskt loggar execution times!

---

## Vilka Stretch Goals Tränar Vad?

- **Lambda vs Proc** - Funktionell programmering, callable objects
- **Error Handling i Hooks** - Robust kod, defensive programming
- **Method Objects** - Metaprogramming, functional programming
- **Configurable Registry** - Configuration patterns, block usage
- **Symbol to_proc** - Ruby's "magic", understanding syntactic sugar
- **Chainable Hooks** - Fluent interfaces, method chaining
- **Memoization** - Performance optimization, caching patterns
- **Timing Hooks** - Performance measurement, profiling

Lycka till! 🎉
