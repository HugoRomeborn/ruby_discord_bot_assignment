# Stretch Goals - Uppgift 5: Encapsulation & Command Registry

Dessa är **valfria** utmaningar för dig som vill öva mer på encapsulation, registries och command management.

---

## 1. Command Aliases

Låt kommandon ha flera namn (aliases). Till exempel: `!help` och `!h` ska göra samma sak.

### Konceptet

```ruby
# Registrera kommando med aliases
registry.register(help_command, aliases: ["h", "?"])

# Alla dessa ska fungera
!help
!h
!?
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_can_register_command_with_aliases
  registry = CommandRegistry.new
  help = HelpCommand.new(registry: registry)

  registry.register(help, aliases: ["h", "?"])

  # Alla varianter ska hitta samma kommando
  assert_equal help, registry.find("!help")
  assert_equal help, registry.find("!h")
  assert_equal help, registry.find("!?")
end
```

**🟢 Implementera:**
- Uppdatera `register` för att ta `aliases: []` parameter
- Registrera huvudkommandot i `@commands` hash
- Loopa genom aliases och registrera varje alias
- Alla ska peka på samma command objekt

**Tips:**
- Använd `normalize_name` för att hantera alias-namn
- Samma command objekt ska finnas på flera nycklar i hashen

---

## 2. Command Categories

Gruppera kommandon i kategorier (Fun, Utility, Admin, etc.).

### Konceptet

```ruby
# Registrera med kategori
registry.register(roll_command, category: "Fun")
registry.register(help_command, category: "Utility")

# !help visar kategoriserade kommandon
📚 **Fun**
• !roll - Roll dice

📚 **Utility**
• !help - Shows all commands
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_can_register_command_with_category
  registry = CommandRegistry.new
  roll = RollCommand.new

  registry.register(roll, category: "Fun")

  assert_equal "Fun", registry.category_for("!roll")
end

def test_can_list_commands_by_category
  registry = CommandRegistry.new
  roll = RollCommand.new
  help = HelpCommand.new(registry: registry)

  registry.register(roll, category: "Fun")
  registry.register(help, category: "Utility")

  fun_commands = registry.commands_in_category("Fun")

  assert_equal 1, fun_commands.length
  assert_includes fun_commands, roll
end
```

**🟢 Implementera:**
- Lägg till `@categories` hash i initialize
- Uppdatera `register` för att ta `category:` parameter
- Implementera `commands_in_category(category_name)`
- Uppdatera HelpCommand för att visa kategorier

---

## 3. Permissions System

Skapa admin-only kommandon som bara vissa användare kan köra.

### Konceptet

```ruby
# Registrera admin-kommando
shutdown = ShutdownCommand.new
registry.register(shutdown, admin_only: true)

# I bot.rb, kolla permissions
if command.admin_only? && !is_admin?(event.user)
  event.respond("❌ Du har inte behörighet att köra detta kommando!")
  return
end
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_can_mark_command_as_admin_only
  registry = CommandRegistry.new
  shutdown = ShutdownCommand.new

  registry.register(shutdown, admin_only: true)

  assert registry.admin_only?("!shutdown")
end

def test_non_admin_cannot_execute_admin_command
  # Test i bot.rb eller genom CommandRegistry wrapper
end
```

**🟢 Implementera:**
- Lägg till `@admin_commands` Set i initialize
- Spara admin-only kommandon där
- Implementera `admin_only?(command_name)` check
- Skapa admin check i bot.rb (t.ex. hardcoded admin user IDs)

**Utmaning:** Var ska admin-listan lagras? Environment variable? Config fil?

---

## 4. Command Cooldowns

Rate limiting - användare kan bara köra vissa kommandon en gång per X sekunder.

### Konceptet

```ruby
# Registrera med cooldown
registry.register(roll_command, cooldown: 5)  # 5 sekunder

# I bot.rb
if registry.on_cooldown?(command_name, event.user.id)
  event.respond("⏳ Vänta #{registry.cooldown_remaining(command_name, event.user.id)} sekunder")
  return
end

registry.mark_used(command_name, event.user.id)
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_on_cooldown
  registry = CommandRegistry.new
  roll = RollCommand.new
  registry.register(roll, cooldown: 5)

  user_id = 123456

  refute registry.on_cooldown?("!roll", user_id)

  registry.mark_used("!roll", user_id)

  assert registry.on_cooldown?("!roll", user_id)
end

def test_cooldown_expires
  registry = CommandRegistry.new
  roll = RollCommand.new
  registry.register(roll, cooldown: 1)  # 1 sekund

  user_id = 123456
  registry.mark_used("!roll", user_id)

  sleep(1.1)  # Vänta lite mer än cooldown

  refute registry.on_cooldown?("!roll", user_id)
end
```

**🟢 Implementera:**
- Lägg till `@cooldowns` hash: `{ "!roll" => { user_id => timestamp } }`
- Implementera `on_cooldown?(command_name, user_id)`
- Implementera `mark_used(command_name, user_id)`
- Implementera `cooldown_remaining(command_name, user_id)`

**Tips:** Använd `Time.now.to_i` för timestamps

---

## 5. Command Statistics

Tracka hur ofta varje kommando används.

### Konceptet

```ruby
# Tracka användning
registry.mark_used("!roll", user_id)

# Visa statistik
stats = registry.statistics
# {
#   "!roll" => { count: 42, last_used: Time, users: [123, 456] },
#   "!help" => { count: 15, last_used: Time, users: [123] }
# }
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_tracks_command_usage
  registry = CommandRegistry.new
  roll = RollCommand.new
  registry.register(roll)

  registry.mark_used("!roll", 123)
  registry.mark_used("!roll", 456)
  registry.mark_used("!roll", 123)

  stats = registry.statistics_for("!roll")

  assert_equal 3, stats[:count]
  assert_equal [123, 456], stats[:unique_users].sort
end
```

**🟢 Implementera:**
- Lägg till `@statistics` hash
- Spara count, last_used, unique users för varje kommando
- Skapa `StatisticsCommand` som visar populäraste kommandon

**Bonus:** Visa i !help hur många gånger varje kommando använts!

---

## 6. Dynamic Command Loading

Ladda kommandon från filer automatiskt istället för att registrera manuellt.

### Konceptet

```ruby
# Alla filer i lib/commands/ laddas automatiskt
lib/commands/
  hello_command.rb
  ping_command.rb
  roll_command.rb

# I bot.rb
registry = CommandRegistry.new
registry.load_commands_from("lib/commands/")

# Automatiskt hittar och registrerar alla Command subklasser
```

### TDD-Process

Detta är mer avancerat och kräver metaprogramming!

**🔴 Skriv tester:**
```ruby
def test_loads_commands_from_directory
  registry = CommandRegistry.new

  registry.load_commands_from("lib/commands/")

  # Alla kommandon i mappen ska vara registrerade
  refute_nil registry.find("!hello")
  refute_nil registry.find("!ping")
end
```

**🟢 Implementera:**

**Vad behöver metoden göra?**
- Använd `Dir.glob` för att hitta alla `*_command.rb` filer i directory
- Ladda varje fil med `require_relative`
- Använd `ObjectSpace.each_object(Class)` för att hitta alla Command subklasser
- Skapa instanser och registrera dem

**Tips:**
- `ObjectSpace.each_object(Class).select { |klass| klass < Command }`
- Kräver att kommandon har default constructors (ingen required params)

**Utmaning:** Hur hanterar du kommandon som behöver dependencies (som HelpCommand behöver registry)?

---

## 7. Command Help Messages

Ge varje kommando mer detaljerad hjälp med exempel.

### Konceptet

```ruby
class RollCommand < Command
  def initialize
    super(
      name: "roll",
      description: "Roll dice",
      usage: "!roll [notation]",
      examples: ["!roll", "!roll d20", "!roll 2d6+3"]
    )
  end
end

# !help roll visar detaljerad info
📚 **!roll**
Description: Roll dice
Usage: !roll [notation]
Examples:
  • !roll
  • !roll d20
  • !roll 2d6+3
```

### TDD-Process

**🔴 Skriv tester:**
```ruby
def test_command_has_detailed_help
  roll = RollCommand.new

  assert_equal "!roll [notation]", roll.usage
  assert_equal 3, roll.examples.length
end

def test_help_command_shows_detailed_help
  registry = CommandRegistry.new
  roll = RollCommand.new
  registry.register(roll)

  help = HelpCommand.new(registry: registry)
  mock_event = MockEvent.new

  help.execute(mock_event, ["roll"])

  response = mock_event.responses.first
  assert_includes response, "Usage: !roll [notation]"
  assert_includes response, "Examples:"
end
```

**🟢 Implementera:**
- Uppdatera Command basklass för att ta `usage:` och `examples:` parametrar
- HelpCommand med argument (`!help roll`) visar detaljerad info
- HelpCommand utan argument visar lista som vanligt

---

## Vilka Stretch Goals Tränar Vad?

- **Command Aliases** - Hash mappings, multiple keys pointing to same value
- **Command Categories** - Grouping, organizing data structures
- **Permissions System** - Authorization, security concepts
- **Command Cooldowns** - Rate limiting, time-based logic
- **Command Statistics** - Data tracking, analytics
- **Dynamic Command Loading** - Metaprogramming, reflection, Dir.glob
- **Command Help Messages** - Documentation, user experience

Lycka till! 🎉
