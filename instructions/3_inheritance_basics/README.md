# Uppgift 3: Inheritance Basics

## Översikt

I denna uppgift ska du lära dig **arv (inheritance)** - ett av de viktigaste koncepten i objektorienterad programmering. Du kommer refaktorera `HelloCommand` och `PingCommand` att ärva från `Command` för att ta bort duplicerad kod och lära dig hur `super` fungerar.

## Förutsättningar

- ✅ Uppgift 2 klar (First Command Class)
- ✅ Din `my_discord_bot/` mapp med `Command`, `HelloCommand`, `PingCommand`

## Lärandemål

Efter denna uppgift ska du kunna:
- Förklara vad arv är och när man ska använda det
- Skapa subklasser med `class Child < Parent`
- Använda `super` för att anropa föräldraklassens metoder
- Override:a metoder från basklassen
- Testa arv-hierarkier
- Identifiera och ta bort duplicerad kod med arv

---

## Din Projektmapp

Du ska **fortsätta arbeta i samma `my_discord_bot/` mapp**!

I denna uppgift kommer du **refaktorera befintliga filer** (inte skapa nya):
```
my_discord_bot/
├── lib/
│   ├── command.rb          # Uppdateras med NotImplementedError
│   ├── hello_command.rb    # Refaktoreras för att använda arv
│   └── ping_command.rb     # Refaktoreras för att använda arv
└── test/
    ├── test_command.rb
    ├── test_hello_command.rb  # Uppdateras med arv-test
    └── test_ping_command.rb   # Uppdateras med arv-test
```

---

## Koncept: Arv (Inheritance)

### Grunderna

**Läs först:** [Arv (Inheritance) i kursboken](https://ntijoh.github.io/Programmering_2/#_arv)

Kursboken förklarar grunderna i arv:
- Vad arv är och varför vi använder det
- "är-en" relationen (is-a relationship)
- Hur man använder `super` för att anropa föräldraklassens metoder
- Method overriding och polymorfism

**Läs kapitlet innan du fortsätter!** Nedan kompletterar vi med specifika detaljer för denna uppgift.

---

### Arv i Vårt Command System

**Problemet:** `HelloCommand` och `PingCommand` duplicerar kod från `Command` (@name, @description, attr_reader).

**Lösningen:** Arv! `HelloCommand` **är ett** `Command` ✅ (is-a relation)

### Keyword Arguments med super

Kursboken använder positionella argument. I denna kurs använder vi **keyword arguments**:

```ruby
class Command
  def initialize(name:, description:)
    @name = name
    @description = description
  end
end

class HelloCommand < Command
  def initialize
    super(name: "hello", description: "Says hello")  # Skicka keyword arguments
  end
end
```

**Viktigt om `super` med keyword arguments:**
- `super(name: name, description: description)` - Skickar specifika keyword arguments
- `super` (utan parenteser) - Skickar ALLA argument som metoden tog emot
- `super()` (tomma parenteser) - Skickar INGA argument

**I denna uppgift:** Använd alltid `super(name: "...", description: "...")` för tydlighet.

### När INTE Använda Arv

❌ **Ingen "är-en" relation:** `User < Database` (User är inte en Database - använd composition)
❌ **Djupa kedjor:** Max 2-3 nivåer, annars blir det förvirrande
**Tumregel:** Om osäker, använd composition istället.

---

## TDD-Approach: Testa Arv

**Testa:**
- ✅ Att subklassen ärver (`assert_kind_of Command, command`)
- ✅ Att ärvda attribut fungerar (super anropades korrekt)
- ✅ Subklassens egna beteende

**Testa INTE:**
- ❌ Föräldraklassens funktionalitet igen (testas redan i `test_command.rb`)

---

## Del 1: Refaktorera HelloCommand och PingCommand

Nu ska vi refaktorera våra befintliga kommandon för att använda arv korrekt.

Att *refaktorera* innebär att förbättra kodens struktur utan att ändra dess beteende.

### Reflektera: Nuvarande Situation

Titta på din `lib/hello_command.rb` och `lib/ping_command.rb` från Uppgift 2.

**Frågor att fundera på:**
- Har de duplicerad kod?
- Skulle de kunna ärva från `Command` klassen?
- Vad skulle behöva ändras?

---

### Uppdatera Command Basklass

Först, låt oss se till att vår `Command` klass är redo att ärvas från.

**Din uppgift:** Öppna `lib/command.rb` och uppdatera `execute` metoden:

```ruby
class Command
  def initialize(name:, description:)
    @name = name
    @description = description
  end

  attr_reader :name, :description

  def execute(event)
    # Basimplementation - subklasser override:ar denna
    raise NotImplementedError, "Subclass must implement execute method" #NYTT
  end
end
```

**Vad är NotImplementedError?**

`NotImplementedError` är ett exception som kastas när en metod MÅSTE implementeras av subklassen.

**Varför använda det?**
- Gör det tydligt att `Command` är en **abstrakt basklass** (inte menad att användas direkt)
- Om någon glömmer override:a `execute` i en subklass får de ett tydligt felmeddelande
- Självdokumenterande kod

**Exempel:**
```ruby
command = Command.new(name: "test", description: "Test")
command.execute(event)
# => NotImplementedError: Subclass must implement execute method

# Men i en subklass som override:ar execute:
hello = HelloCommand.new
hello.execute(event)  # Fungerar! HelloCommand har implementerat execute
```

---

### Test 1: Refaktorera HelloCommand med Arv

#### 🔴 RED - Uppdatera Testet

Öppna `test/test_hello_command.rb`.

**Först, lägg till require för Command klassen (längst upp i filen):**

```ruby
require_relative 'spec_helper'
require_relative '../lib/hello_command'
require_relative '../lib/command'
```

**Sedan, lägg till ett test för arv:**

```ruby
def test_hello_command_inherits_from_command
  command = HelloCommand.new

  assert_instance_of HelloCommand, command  # Är en HelloCommand
  assert_kind_of Command, command          # Är också en Command (arv!)
end
```

**Kör testet:**
```bash
ruby test/test_hello_command.rb
```

**Testet ska MISSLYCKAS** eftersom HelloCommand inte ärver från Command än. Du ska se något liknande:

```
1) Failure:
TestHelloCommand#test_hello_command_inherits_from_command:
Expected #<HelloCommand:...> to be a kind of Command, not HelloCommand.
```

Detta är korrekt! HelloCommand ärver inte från Command än. Detta är förväntat - vi är i RED-fasen!

#### 🟢 GREEN - Refaktorera HelloCommand

Innan du börjar koda, fundera:

**Reflektionsfrågor:**
- Vilken kod finns i både `Command` och `HelloCommand`? (Tips: titta på `@name`, `@description`, `attr_reader`)
- Vad kan du ta bort från `HelloCommand` om den ärver från `Command`?
- Vad behöver `HelloCommand` fortfarande ha själv?

---

**Din uppgift:** Uppdatera `lib/hello_command.rb` för att ärva från `Command`.

**Refaktoreringschecklist:**

1. **Lägg till require** (längst upp i filen):
   ```ruby
   require_relative 'command'
   ```

2. **Lägg till arv** i class-definitionen:
   ```ruby
   class HelloCommand < Command
   ```

3. **Ta bort duplicerad kod:**
   - ❌ Ta bort `attr_reader :name, :description` (ärvs från Command nu!)
   - ❌ Ta bort `@name = ...` och `@description = ...` från initialize

4. **Uppdatera constructor** för att använda `super`:
   ```ruby
   def initialize
     super(name: "hello", description: "Säger hej!")
   end
   ```

5. **Behåll `execute` metoden** (den override:ar Command#execute):
   ```ruby
   def execute(event)
     event.respond("Hello!")
   end
   ```

**Kör alla tester:**
```bash
ruby test/test_hello_command.rb
ruby test/test_command.rb
```

Alla ska passera! Om något failar, felsök innan du går vidare.

---

**Reflektion efter refaktorering:**
- Hur många rader kod tog du bort från HelloCommand?
- Om du nu vill lägga till något nytt som ALLA kommandon ska ha (t.ex. en ny instansvariabel), hur många filer måste du ändra?
- Svar: Bara Command! Alla subklasser ärver automatiskt den nya funktionaliteten.

---

### Test 2: Refaktorera PingCommand med Arv

**Din uppgift:** Gör samma sak för `PingCommand`.

1. 🔴 Lägg till arv-test i `test/test_ping_command.rb`
2. 🟢 Refaktorera `lib/ping_command.rb` att ärva från `Command`
3. Kör tester - alla ska passa!

**OBS:** Har du duplicerad kod kvar i `lib/ping_command.rb`?

---

## Grattis!

Du har nu:
- ✅ Refaktorerat HelloCommand och PingCommand att använda arv
- ✅ Förstår varför arv tar bort duplicering
- ✅ Kan använda `super` med keyword arguments
- ✅ Har testat arv-hierarkier

**Kör din bot och testa att allt fortfarande fungerar:**
```bash
ruby bot.rb
```

Testa `!hello` och `!ping` i Discord - de ska fungera precis som förut, men nu med mycket bättre kod! 🎉

---

## Nästa Steg

I **Uppgift 4** kommer vi lära oss:
- **Polymorfism** - Olika klasser, samma interface
- **TextCommand** - En generisk klass för enkla textkommandon
- **RollCommand** - Tärningsrullning med command arguments
- **Command arguments** - Hur kommandon tar input från användare

**Pausa här!** Du har lärt dig arv grundligt. Nästa uppgift bygger vidare på detta. 🎯

---

## Resurser

- [Arv i kursboken](https://ntijoh.github.io/Programmering_2/#_arv)
- [Ruby Inheritance Documentation](https://ruby-doc.org/core-3.1.0/Class.html#method-i-3C)
- [Understanding super in Ruby](https://www.rubyguides.com/2018/09/ruby-super-keyword/)
- [When to Use Inheritance](https://thoughtbot.com/blog/back-to-basics-inheritance)
