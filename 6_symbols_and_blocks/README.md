# Uppgift 6: Symbols & Blocks

## Översikt

I denna uppgift ska du lära dig två viktiga Ruby-koncept: **symbols** och **blocks**. Du kommer refaktorera din CommandRegistry att använda symbols som hash-nycklar och lägga till callback-system med blocks.

## Förutsättningar

- ✅ Uppgift 5 klar (Encapsulation & Command Registry)
- ✅ Din `my_discord_bot/` mapp med fungerande CommandRegistry

## ⚠️ VIKTIGT: Fortsätt i Din Bot-Mapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara skillnaden mellan symbols och strings
- Förstå varför symbols är bättre som hash-nycklar
- Använda blocks med `yield` och `block_given?`
- Skapa callback-system (before/after hooks)
- Bygga custom iterators med blocks
- Förstå när man ska använda blocks vs metoder

---

## Koncept: Symbols

### Vad är Symbols?

Du har faktiskt redan använt symbols! När du skrev `name:` i keyword arguments använde du en symbol.

```ruby
# Keyword arguments använder symbols
command = Command.new(name: "hello", description: "Says hello")
#                     ^^^^             ^^^^^^^^^^^
#                     Dessa är symbols!
```

**Symbol syntax:**
```ruby
:hello        # En symbol
"hello"       # En string
```

**Skillnader:**

| String | Symbol |
|--------|--------|
| `"hello"` | `:hello` |
| Muterbar (kan ändras) | Immutable (kan INTE ändras) |
| Ny instans varje gång | Samma objekt varje gång |
| Använd för text som visas/ändras | Använd för identifierare/nycklar |

### Varför Symbols för Hash Keys?

**Symbols är immutable och återanvänds:**
```ruby
# Strings - nytt objekt varje gång
"hello".object_id  # => 70123456789000
"hello".object_id  # => 70123456789020  (olika!)

# Symbols - samma objekt varje gång
:hello.object_id  # => 1234567
:hello.object_id  # => 1234567  (samma!)
```

**I vår CommandRegistry:**
```ruby
# Med strings (nuvarande)
@commands["!hello"] = command  # Ny string varje lookup

# Med symbols (bättre)
@commands[:hello] = command  # Samma symbol återanvänds, snabbare!
```

### När Använda Symbols vs Strings

✅ **Använd symbols för:**
- Hash keys
- Identifierare (namn på saker)
- Interna värden som inte ändras
- Method names, attribute names

✅ **Använd strings för:**
- Text som ska visas till användare
- Data från input/filer
- Text som kan ändras
- Meddelanden, beskrivningar

**Exempel:**
```ruby
# ✅ BRA
user = { name: "Alice", age: 25 }  # Keys är symbols
puts user[:name]                   # "Alice" (värdet är string)

# ❌ DÅLIGT
user = { "name" => "Alice" }       # Strings som keys (slöseri)
```

---

## Del 1: Refaktorera CommandRegistry med Symbols

Nu ska vi uppdatera CommandRegistry att använda symbols som hash-nycklar istället för strings - snabbare lookups och mindre minnesanvändning!

### Test 1: Registry Använder Symbols Internt

#### 🔴 RED - Uppdatera Testet

Öppna `test/test_command_registry.rb` och lägg till:

```ruby
def test_registry_uses_symbols_as_keys
  registry = CommandRegistry.new
  hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")

  registry.register(hello)

  # Kan fortfarande hitta med string
  assert_equal hello, registry.find("!hello")
  assert_equal hello, registry.find("hello")

  # Kan också hitta med symbol direkt
  assert_equal hello, registry.find(:hello)
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Refaktorera CommandRegistry

**Din uppgift:** Uppdatera `lib/command_registry.rb`

**Vad ska ändras:**

1. **I `register` metoden:**
   - Konvertera command.name till symbol: `command.name.to_sym`
   - Spara med symbol som key: `@commands[:hello]` istället för `@commands["!hello"]`

2. **I `find` metoden:**
   - Normalisera input till symbol
   - Ta bort `!` först, sen konvertera till symbol
   - Använd symbol för hash-lookup

3. **Tips för normalisering:**
   - `name.to_s.strip.downcase.gsub(/^!/, '').to_sym`
   - Tar emot string eller symbol
   - Tar bort whitespace och `!`
   - Konverterar till symbol

**Kör testet** - det ska passa!

---

### Test 2: Symbolvänlig find-metod

**Din uppgift:** Lägg till test som verifierar att `find` accepterar både strings och symbols:

```ruby
def test_find_accepts_strings_and_symbols
  registry = CommandRegistry.new
  command = TextCommand.new(name: "test", description: "Test", text: "Test!")
  registry.register(command)

  # Alla dessa ska fungera
  assert_equal command, registry.find("test")
  assert_equal command, registry.find(:test)
  assert_equal command, registry.find("!test")
  assert_equal command, registry.find("  TEST  ")
end
```

**Kör testet** - det ska passa om din refaktorering är korrekt!

---

## Koncept: Blocks

### Vad är Blocks?

Blocks är "code chunks" som du kan skicka till metoder. Du har redan använt dem!

**Du har sett blocks här:**
```ruby
# Array iteration
[1, 2, 3].each do |number|
  puts number
end

# Sinatra routes (från webserver-kursen!)
get '/hello' do
  "Hello World!"
end

post '/users' do
  # Hantera POST request
end
```

**Block syntax:**
```ruby
# Do...end (multi-line)
array.each do |item|
  puts item
  puts item * 2
end

# Curly braces (single-line)
array.each { |item| puts item }
```

### Blocks med yield

Du kan skapa egna metoder som tar emot blocks med `yield`:

```ruby
def greet
  puts "Before greeting"
  yield  # Kör blocket som skickades in
  puts "After greeting"
end

greet do
  puts "Hello!"
end

# Output:
# Before greeting
# Hello!
# After greeting
```

**Med parametrar till blocket:**
```ruby
def greet_person(name)
  yield(name)  # Skicka name till blocket
end

greet_person("Alice") do |person|
  puts "Hello, #{person}!"
end
# => "Hello, Alice!"
```

### block_given?

Kolla om ett block skickades in:

```ruby
def maybe_greet
  if block_given?
    yield
  else
    puts "No block provided"
  end
end

maybe_greet                    # => "No block provided"
maybe_greet { puts "Hello!" }  # => "Hello!"
```

---

## Del 2: Command Hooks med Blocks

Nu ska vi lägga till callback-system till CommandRegistry - möjligheten att köra kod före och efter kommandon exekveras.

### Konceptet: Callbacks/Hooks

**Use case:** Logga varje gång ett kommando körs:

```ruby
registry.before_execute do |command_name|
  puts "Running command: #{command_name}"
end

registry.after_execute do |command_name|
  puts "Finished command: #{command_name}"
end
```

### Spara Blocks med &block

För att kunna spara blocks (som i hooks-arrayen ovan) behöver vi förstå `&block`:

**Problemet:**
```ruby
def save_hook(block)
  @hooks << block  # Hur får vi tag på blocket som skickas in?
end

save_hook do
  puts "This is a block"
end
# Fungerar INTE - "block" är bara en parameter-namn, inte själva blocket!
```

**Lösningen: &block**
```ruby
def save_hook(&block)
  @hooks << block  # & konverterar blocket till en Proc vi kan spara
end

save_hook do
  puts "This is a block"
end
# Fungerar! Block är nu sparat i @hooks
```

**Vad gör `&`?**
- I metoddefinition (`def foo(&block)`): Konverterar block → Proc och sparar i variabeln `block`
- Vid metodanrop (`array.each(&my_proc)`): Konverterar Proc → block

**Anropa sparade blocks:**
```ruby
@hooks.each do |hook|
  hook.call  # Anropa blocket som sparats
end
```

**Key points:**
- `&block` i parameterlista = "fånga blocket som skickas in"
- Blocket konverteras till en Proc (callable object)
- Använd `.call` för att köra det sparade blocket

---

### Test 1: Registry Kan Registrera Hooks

#### 🔴 RED - Skriv Testet

Öppna `test/test_command_registry.rb` och lägg till:

```ruby
def test_can_register_before_execute_hook
  registry = CommandRegistry.new
  hook_called = false

  registry.before_execute do
    hook_called = true
  end

  # Simulera att ett kommando körs
  registry.trigger_before_hooks

  assert hook_called, "Before hook should have been called"
end
```

**Kör testet** - det ska misslyckas.

#### 🟢 GREEN - Implementera Hooks

**Din uppgift:** Uppdatera `CommandRegistry`

**Vad behövs:**

1. **I `initialize`:**
   - Skapa `@before_hooks = []`
   - Skapa `@after_hooks = []`

2. **Lägg till metoder för att registrera hooks:**
```ruby
def before_execute(&block)
  @before_hooks << block
end

def after_execute(&block)
  @after_hooks << block
end
```

3. **Lägg till trigger-metoder:**
   - `trigger_before_hooks(command_name = nil)` - Iterera över `@before_hooks`, anropa varje hook med `.call`
   - Om `command_name` finns, skicka det till `hook.call(command_name)`
   - Samma mönster för `trigger_after_hooks`

**Kör testet** - det ska passa!

---

### Test 2: Hooks Får Command Name

**Din uppgift:** Lägg till test som verifierar att hooks får command name som parameter:

```ruby
def test_hooks_receive_command_name
  registry = CommandRegistry.new
  received_name = nil

  registry.before_execute do |name|
    received_name = name
  end

  registry.trigger_before_hooks(:hello)

  assert_equal :hello, received_name
end
```

---

## Del 3: Integrera Hooks i bot.rb

Nu ska vi använda våra hooks för att se när kommandon körs!

**Din uppgift:** Uppdatera `bot.rb`

**Efter du skapat registry, lägg till hooks:**

```ruby
# Visa när kommandon körs (enkelt med puts)
registry.before_execute do |command_name|
  puts "▶️  Running: !#{command_name}"
end

registry.after_execute do |command_name|
  puts "✅ Done: !#{command_name}"
end
```

**Notera:** I nästa uppgift (Assignment 7) kommer vi lära oss **Dependency Injection** och refaktorera detta till att använda en riktig Logger-klass istället för `puts`!

**I message handler:**
1. Hitta kommandot med `registry.find(command_name)`
2. Normalisera namnet till symbol (ta bort `!`, lowercase, `.to_sym`)
3. Trigga `before_hooks` med normaliserat namn
4. Kör kommandot (kom ihåg att RollCommand tar args!)
5. Trigga `after_hooks` med normaliserat namn

### Testa!

```bash
ruby bot.rb
```

När du kör kommandon i Discord ska du nu se:
```
▶️  Running command: !hello
✅ Finished command: !hello
```

---

## Del 4: Custom Iterator med Block

Låt oss skapa en iterator för CommandRegistry som låter oss loopa genom kommandon med en block!

### Test: Registry#each Iterator

#### 🔴 RED - Skriv Testet

```ruby
def test_can_iterate_over_commands
  registry = CommandRegistry.new
  hello = TextCommand.new(name: "hello", description: "Says hello", text: "Hello!")
  ping = TextCommand.new(name: "ping", description: "Pings", text: "Pong!")

  registry.register(hello)
  registry.register(ping)

  commands_seen = []
  registry.each do |name, command|
    commands_seen << name
  end

  assert_equal 2, commands_seen.length
  assert_includes commands_seen, :hello
  assert_includes commands_seen, :ping
end
```

#### 🟢 GREEN - Implementera each

**Din uppgift:** Lägg till `each` metoden i CommandRegistry:

```ruby
def each(&block)
  @commands.each(&block)
end
```

**Vad gör `&block`?**
- Tar emot blocket som skickas till `each`
- Skickar det vidare till `@commands.each`
- `@commands` är en hash, så blocket får `|key, value|` parametrar

**Kör testet** - det ska passa!

---

## Vanliga Misstag

### 1. Glömma Konvertera Strings till Symbols

```ruby
# ❌ FEL - Blandar strings och symbols
@commands["hello"] = command
result = @commands[:hello]  # => nil (olika keys!)

# ✅ RÄTT - Konsekvent med symbols
@commands[:hello] = command
result = @commands[:hello]  # => fungerar!
```

### 2. Glömma & vid Block-Parameter

```ruby
# ❌ FEL - Block hamnar i vanlig variabel (blir Proc)
def before_execute(block)
  @hooks << block
end

# ✅ RÄTT - & konverterar block till block-parameter
def before_execute(&block)
  @hooks << block
end
```

### 3. Anropa Block Fel

```ruby
# ❌ FEL - Försöker anropa som metod
def trigger_hooks
  @hooks.each { |hook| hook }  # Gör ingenting!
end

# ✅ RÄTT - Använd .call
def trigger_hooks
  @hooks.each { |hook| hook.call }
end
```

---

## Reflektion: Vad Lärde Du Dig?

Efter denna uppgift ska du kunna svara på:

1. **Vad är skillnaden mellan symbols och strings?**
   - Svar: Symbols är immutable och återanvänds (samma object_id), strings är muterbara. Symbols perfekt för hash keys.

2. **Varför är symbols bättre som hash-nycklar?**
   - Svar: Snabbare lookups, mindre minnesanvändning, tydligare kod (visar att det är en identifierare).

3. **Vad är ett block?**
   - Svar: Ett "code chunk" som kan skickas till metoder. Används med `do...end` eller `{ }`.

4. **När skulle du använda blocks?**
   - Svar: Callbacks, iterators, konfiguration, när du vill låta användaren "plugga in" beteende.

5. **Vad gör `yield`?**
   - Svar: Kör blocket som skickades till metoden.

---

## Stretch Goals (Valfritt)

Vill du lära dig mer? Kolla in `STRETCH_GOALS.md` för utmaningar som:
- **Lambda vs Proc** - Skillnader och när man ska använda vardera
- **Method objects** - Konvertera metoder till objekt
- **Error handling i hooks** - Vad händer om en hook kraschar?
- **Och mer...**

---

## Nästa Steg

I **Uppgift 7 (Dependency Injection)** kommer vi lära oss:
- **Dependency Injection pattern** - Skicka in dependencies istället för att skapa dem
- **Logger injection** - Refaktorera våra `puts` till en riktig Logger-klass
- **Testability** - Varför DI gör kod lättare att testa (kan mocka logger!)
- **Configuration** - Konfigurera objekt flexibelt

**Grattis!** Du har lärt dig symbols och blocks - två kraftfulla Ruby-features! 🎉

## Resurser

- [Ruby Symbols Explained](https://www.rubyguides.com/2018/02/ruby-symbols/)
- [Understanding Ruby Blocks](https://www.rubyguides.com/2016/02/ruby-procs-and-lambdas/)
- [yield and block_given?](https://www.rubyguides.com/2019/12/ruby-yield-keyword/)
- [Ruby Style Guide - Symbols as Keys](https://rubystyle.guide/#symbols-as-keys)
