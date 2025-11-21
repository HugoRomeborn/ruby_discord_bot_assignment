# Uppgift 0: TDD Fundamentals - Test-Driven Development

## Översikt

Innan vi börjar bygga vår Discord-bot ska du lära dig **Test-Driven Development (TDD)** - en metod där du skriver tester *före* du skriver koden. Detta kan kännas bakvänt i början, men det är en kraftfull teknik som leder till bättre kod och färre buggar.

I denna uppgift bygger du en enkel `Calculator` klass för att öva på TDD-cykeln utan distraktion från Discord API:et.

## Förutsättningar

- Grundläggande Ruby-kunskaper (klasser, metoder, variabler)
- Ruby installerat (version 3.0+)

## Lärandemål

Efter denna uppgift ska du kunna:
- Förstå **Red-Green-Refactor** cykeln
- Skriva tester med **Minitest**
- Förstå skillnaden mellan att testa *beteende* vs *implementation*
- Använda assertions (`assert_equal`, `assert_nil`, `assert_raises`, etc.)
- Köra tester och tolka felmeddelanden
- Skriva minimal kod för att få tester att passera

## Koncept: Test-Driven Development (TDD)

### Vad är TDD?

Test-Driven Development är en utvecklingsmetod där du:
1. **Skriver ett test först** (som misslyckas eftersom koden inte finns än)
2. **Skriver minimal kod** för att få testet att passera
3. **Refaktorerar** koden för att göra den bättre

Detta upprepas för varje ny feature.

### Red-Green-Refactor Cykeln

```
🔴 RED    → Skriv ett test som misslyckas
           (Koden finns inte än)

🟢 GREEN  → Skriv minimal kod som får testet att passera
           (Gör det enklaste som fungerar)

🔵 REFACTOR → Förbättra koden utan att ändra beteende
           (Testerna ska fortfarande passera)
```

**Exempel:**

```ruby
# 🔴 RED - Skriv test först
def test_greeting_returns_hello
  greeter = Greeter.new
  assert_equal "Hello!", greeter.greet
end
# Test misslyckas: Greeter klass finns inte!

# 🟢 GREEN - Skriv minimal kod
class Greeter
  def greet
    "Hello!"  # Hårdkodat! Men testet passerar...
  end
end
# Test passerar!

# Nu skriver vi fler tester för att tvinga fram riktig implementation
def test_greeting_with_name
  greeter = Greeter.new("Alice")
  assert_equal "Hello, Alice!", greeter.greet
end
# Test misslyckas!

# 🟢 GREEN - Nu måste vi skriva riktig logik
class Greeter
  def initialize(name = "")
    @name = name
  end

  def greet
    @name.empty? ? "Hello!" : "Hello, #{@name}!"
  end
end
# Båda testerna passerar!

# 🔵 REFACTOR - Koden är redan bra, ingen refaktorering behövs
```

### Varför TDD?

**Fördelar:**
- ✅ **Tester skrivs alltid** - inte "jag lägger till dem senare" (som aldrig händer)
- ✅ **Bättre design** - kod som är lätt att testa är ofta bra designad
- ✅ **Mindre buggar** - du vet direkt om något går sönder
- ✅ **Dokumentation** - tester visar hur koden ska användas
- ✅ **Trygghet vid refaktorering** - tester fångar upp om något går sönder

**Nackdelar:**
- ⚠️ Tar längre tid i början (men sparar tid senare)
- ⚠️ Kräver disciplin att följa processen

### Testa Beteende, Inte Implementation

**Dåligt test (testar implementation):**
```ruby
def test_calculator_has_result_variable
  calculator = Calculator.new
  calculator.add(2, 3)
  assert_equal 5, calculator.instance_variable_get(:@result)
end
```
Varför dåligt? Om du byter namn på variabeln går testet sönder, trots att beteendet är samma.

**Bra test (testar beteende):**
```ruby
def test_add_returns_sum
  calculator = Calculator.new
  result = calculator.add(2, 3)
  assert_equal 5, result
end
```
Varför bra? Du testar *vad klassen gör*, inte *hur den gör det*.

## Minitest Basics

Ruby har flera testramverk. Vi använder **Minitest** eftersom det är enkelt och ingår i Ruby.

### Grundstruktur

```ruby
require 'minitest/autorun'

class TestCalculator < Minitest::Test
  def test_something
    # Arrange (förbered)
    calculator = Calculator.new

    # Act (utför)
    result = calculator.add(2, 3)

    # Assert (kontrollera)
    assert_equal 5, result
  end
end
```

### Vanliga Assertions

| Assertion | Vad den gör |
|-----------|-------------|
| `assert_equal expected, actual` | Kontrollerar att två värden är lika |
| `assert value` | Kontrollerar att värdet är truthy |
| `refute value` | Kontrollerar att värdet är falsy |
| `assert_nil value` | Kontrollerar att värdet är nil |
| `assert_instance_of Class, object` | Kontrollerar att object är en instans av Class |
| `assert_raises(ErrorClass) { code }` | Kontrollerar att kod kastar ett specifikt fel |
| `assert_in_delta expected, actual, delta` | Kontrollerar att nummer är nära varandra (för decimaler) |

[Minitest Documentation](https://docs.seattlerb.org/minitest/)

### Köra Tester

```bash
# Kör alla tester i en fil
ruby test_calculator.rb

# Kör ett specifikt test
ruby test_calculator.rb --name test_add_returns_sum
```

## Del 1: Din Första TDD-Cykel

Nu ska du bygga en `Calculator` klass med TDD. Följ Red-Green-Refactor cykeln!

### Setup: Skapa Filer

Skapa en projektmapp och två filer:

```bash
mkdir calculator_tdd
cd calculator_tdd
touch calculator.rb
touch test_calculator.rb
```

### Test 1: Räknaren kan skapas

#### 🔴 RED - Skriv testet först

Öppna `test_calculator.rb` och skriv:

```ruby
require 'minitest/autorun'
require_relative 'calculator'

class TestCalculator < Minitest::Test
  def test_calculator_can_be_created
    calculator = Calculator.new
    # Om vi kommer hit utan error har vi lyckats!
    assert_instance_of Calculator, calculator
  end
end
```

**Kör testet:**
```bash
ruby test_calculator.rb
```

Du ska se ett fel: `uninitialized constant Calculator (NameError)`

Detta är förväntat! Vi är i **RED** fasen.

#### 🟢 GREEN - Skriv minimal kod

Öppna `calculator.rb` och skriv:

```ruby
class Calculator
end
```

**Kör testet igen:**
```bash
ruby test_calculator.rb
```

Det ska passera! Du är i **GREEN** fasen.

#### 🔵 REFACTOR - Förbättra (om nödvändigt)

Koden är redan enkel och tydlig. Ingen refaktorering behövs.

**Grattis!** Du har gjort din första TDD-cykel! 🎉

---

### Test 2: Räknaren kan addera två tal

#### 🔴 RED - Skriv testet

Lägg till detta test i `test_calculator.rb`:

```ruby
def test_add_returns_sum_of_two_numbers
  calculator = Calculator.new
  result = calculator.add(2, 3)
  assert_equal 5, result
end
```

**Kör testet** - det ska misslyckas med `undefined method 'add'`

#### 🟢 GREEN - Implementera

**Din uppgift:** Lägg till en `add` metod i `Calculator` klassen som returnerar summan av två tal.

**Tips:** Håll det enkelt - metoden ska bara ta två parametrar och returnera deras summa.

**Kör testet** - det ska passera!

---

### Test 3: Addera olika tal

#### 🔴 RED - Skriv testet

**Din uppgift:** Skriv ett test som kontrollerar att `add` fungerar med andra tal, t.ex. 10 + 7.

**Kör testet** - om din `add` metod är korrekt implementerad ska det passera direkt!

---

### Test 4: Räknaren kan subtrahera

#### 🔴 RED - Skriv testet

**Din uppgift:** Skriv ett test för en `subtract` metod som subtraherar två tal.

**Exempel:**
- `subtract(5, 3)` ska returnera `2`
- `subtract(10, 7)` ska returnera `3`

**Kör testet** - det ska misslyckas (metoden finns inte)

#### 🟢 GREEN - Implementera

**Din uppgift:** Implementera `subtract` metoden.

**Kör testet** - det ska passera!

---

### Test 5: Räknaren kan multiplicera

**Din uppgift:** Följ TDD-cykeln för att lägga till en `multiply` metod.

1. 🔴 Skriv test först
2. 🟢 Implementera metoden
3. 🔵 Refaktorera om nödvigt

---

### Test 6: Räknaren kan dividera

**Din uppgift:** Följ TDD-cykeln för att lägga till en `divide` metod.

1. 🔴 Skriv test först
2. 🟢 Implementera metoden
3. 🔵 Refaktorera om nödvigt

**Tips:** Vad ska hända om någon försöker dividera med 0? (Vi hanterar det i nästa steg!)

---

## Del 2: Lägg till Felhantering med TDD

Nu ska du lägga till validering och felhantering - fortsätt följa TDD-cykeln!

### Feature: Division med noll ska kasta ett fel

**Uppgift:** Division med noll är matematiskt ogiltigt. Din `divide` metod ska kasta ett `ArgumentError` när nämnaren är 0.

#### 🔴 RED - Skriv test

```ruby
def test_divide_by_zero_raises_error
  calculator = Calculator.new
  assert_raises(ArgumentError) do
    calculator.divide(10, 0)
  end
end
```

**Kör testet** - det ska misslyckas (metoden kastar inget fel än)

#### 🟢 GREEN - Implementera

**Din uppgift:** Uppdatera din `divide` metod för att kontrollera om `b` är 0, och i så fall `raise ArgumentError, "Cannot divide by zero"`

**Kör testet** - det ska passera!

#### 🔵 REFACTOR

Är din felhantering tydlig? Är felmeddelandet hjälpsamt?

---

### Feature: Validera att input är nummer

**Uppgift:** Räknaren ska bara acceptera numeriska värden. Om någon försöker använda strängar eller andra typer ska ett `TypeError` kastas med ett tydligt felmeddelande.

#### 🔴 RED - Skriv tester

**Din uppgift:** Skriv tester som kontrollerar att `add` (och andra metoder) kastar `TypeError` med ett specifikt felmeddelande när de får icke-numeriska argument.

**Viktigt:** Ruby's `+` operator kastar redan `TypeError` för `"hello" + 5`, men med ett generiskt felmeddelande. Vi vill ha ett **tydligt, hjälpsamt** felmeddelande som "Arguments must be numeric".

**Exempel:**
```ruby
def test_add_with_string_raises_error_with_message
  calculator = Calculator.new
  error = assert_raises(TypeError) do
    calculator.add("hello", 5)
  end
  assert_equal "Arguments must be numeric", error.message
end
```

Skriv liknande tester för `subtract`, `multiply`, och `divide`.

**Kör testerna** - de ska misslyckas (Ruby's standardfelmeddelande är annorlunda)

#### 🟢 GREEN - Implementera

**Din uppgift:** Lägg till validering i början av varje metod:

```ruby
def add(a, b)
  raise TypeError, "Arguments must be numeric" unless a.is_a?(Numeric) && b.is_a?(Numeric)
  a + b
end
```

Gör samma för alla operationer.

**Kör testerna** - de ska passera!

#### 🔵 REFACTOR

**Notera:** Varje metod har nu samma validering - det är kod-duplicering! Vi kan förbättra detta.

**Din uppgift:** Skapa en privat metod `validate_numeric` som du kan anropa i alla operationer:

```ruby
private

def validate_numeric(a, b)
  raise TypeError, "Arguments must be numeric" unless a.is_a?(Numeric) && b.is_a?(Numeric)
end
```

Uppdatera dina metoder att använda denna. **Kör alla tester** - de ska fortfarande passera!

---

## Del 3: Lägg till Mer Funktionalitet

### Feature: Potens (power)

**Uppgift:** Lägg till en `power(base, exponent)` metod som beräknar base^exponent.

**TDD-process:**
1. 🔴 Skriv test: `power(2, 3)` ska returnera `8`
2. 🔴 Skriv test: `power(5, 2)` ska returnera `25`
3. 🟢 Implementera metoden
4. 🔴 Skriv test för negativa exponenter (vad ska hända?)
5. 🟢 Hantera negativa exponenter

**Tips:** Ruby har `**` operatorn för potens: `2 ** 3 == 8`

---

### Feature: Kvadratrot (square root)

**Uppgift:** Lägg till en `sqrt(number)` metod som beräknar kvadratroten.

**TDD-process:**
1. 🔴 Skriv test: `sqrt(9)` ska returnera `3.0`
2. 🔴 Skriv test: `sqrt(16)` ska returnera `4.0`
3. 🟢 Implementera metoden
4. 🔴 Skriv test: `sqrt(-4)` ska kasta `ArgumentError` (ingen reell kvadratrot)
5. 🟢 Implementera felhantering

**Tips:** Ruby har `Math.sqrt()` metoden.

---

### Feature: Memory (kom ihåg senaste resultatet)

**Uppgift:** Lägg till funktionalitet för att komma ihåg det senaste resultatet.

**TDD-process:**
1. 🔴 Skriv test: efter `add(2, 3)` ska `last_result` returnera `5`
2. 🟢 Implementera: spara resultat i `@last_result` instansvariabel, lägg till `attr_reader :last_result`
3. 🔴 Skriv test: efter flera operationer ska `last_result` vara det senaste
4. 🔴 Skriv test: `clear` metod ska sätta `last_result` till `nil`
5. 🟢 Implementera `clear` metoden

**Exempel:**
```ruby
calculator = Calculator.new
calculator.add(2, 3)
assert_equal 5, calculator.last_result
calculator.multiply(4, 5)
assert_equal 20, calculator.last_result
calculator.clear
assert_nil calculator.last_result
```

---

### Feature: Chainable operations (valfritt avancerat)

**Uppgift:** Gör så att räknaren kan kedja operationer genom att returnera `self`.

**TDD-process:**
1. 🔴 Skriv test för kedjning:
```ruby
result = calculator.add(5, 3).multiply(2, 2).subtract(10, 1)
assert_equal 9, calculator.last_result
```

2. 🟢 Uppdatera metoder att returnera `self` istället för resultatet
3. 🔴 Hur påverkar detta tidigare tester? Behöver de uppdateras?

---

## Vanliga Misstag

### 1. Skriva för mycket kod på en gång

```ruby
# ❌ FEL - Implementerar allt direkt
class Calculator
  def initialize
    @last_result = nil
  end

  def add(a, b)
    validate_numeric(a, b)
    @last_result = a + b
  end

  def subtract(a, b)
    validate_numeric(a, b)
    @last_result = a - b
  end

  # ... massa kod utan tester
end
```

**Varför fel?** Du ska bara skriva kod för att få *nuvarande test* att passera.

```ruby
# ✅ RÄTT - Bygg steg för steg
# Först: bara tom klass (för test 1)
# Sen: lägg till add (för test 2)
# Sen: lägg till subtract (för test 3)
# Osv...
```

---

### 2. Testa implementation istället för beteende

```ruby
# ❌ FEL - Testar intern implementation
def test_add_uses_plus_operator
  calculator = Calculator.new
  # Försöker testa HUR koden gör något - för detaljerat!
end

# ✅ RÄTT - Testar beteende
def test_add_returns_sum
  calculator = Calculator.new
  result = calculator.add(2, 3)
  assert_equal 5, result
end
```

---

### 3. Glömma att köra tester ofta

**Workflow:**
1. Skriv test
2. **Kör test (ska misslyckas)** ← Verifiera att du är i RED!
3. Skriv kod
4. **Kör test (ska passera)** ← Verifiera att du är i GREEN!
5. Refaktorera
6. **Kör test (ska fortfarande passera)** ← Verifiera att refaktoreringen inte förstörde något!

Kör tester **ofta** - efter varje liten förändring!

---

### 4. Hårdkoda för att få test att passera (och stanna där)

```ruby
# 🟢 OK som första steg
def add(a, b)
  5  # Får första testet att passera
end

# ❌ FEL - Stanna här
# Du måste skriva fler tester som tvingar fram riktig logik!

# ✅ RÄTT - Skriv fler tester tills du måste implementera ordentligt
def test_add_different_numbers
  assert_equal 10, calculator.add(7, 3)
end
# Nu måste du skriva: a + b
```

---

### 5. Testa privata metoder direkt

```ruby
# ❌ FEL - Testar privat metod direkt
def test_validate_numeric_works
  calculator = Calculator.new
  # Försöker testa privat metod...
end

# ✅ RÄTT - Testa privata metoder indirekt via publika metoder
def test_add_with_string_raises_error
  calculator = Calculator.new
  assert_raises(TypeError) { calculator.add("hello", 5) }
  # Detta testar validate_numeric indirekt
end
```

**Princip:** Testa bara publika interfaces. Privata metoder testas indirekt genom de publika metoderna som använder dem.

---

## Stretch Goals (Valfritt)

### 1. Calculator med history

Spara en lista över alla operationer som har gjorts:

```ruby
calculator = Calculator.new
calculator.add(2, 3)
calculator.multiply(4, 5)

assert_equal ["2 + 3 = 5", "4 * 5 = 20"], calculator.history
```

**TDD Challenge:**
- Testa att varje operation läggs till i historiken
- Testa att `clear_history` rensar listan
- Testa att historiken formateras korrekt

---

### 2. Scientific Calculator

Lägg till vetenskapliga funktioner:
- `sin(angle)`, `cos(angle)`, `tan(angle)`
- `log(number)`, `ln(number)`
- `factorial(n)` (t.ex. `5! = 120`)

**TDD Challenge:**
- Hur testar du trigonometriska funktioner? (Hint: `assert_in_delta` för decimaler)
- Hur hanterar du `factorial` för negativa tal?

---

### 3. Reverse Polish Notation (RPN) Calculator

Bygg en RPN-kalkylator (som HP-räknare):

```ruby
calculator = RPNCalculator.new
calculator.push(5)
calculator.push(3)
calculator.add  # => 8 (5 + 3)
calculator.push(2)
calculator.multiply  # => 16 (8 * 2)
```

**TDD Challenge:**
- Testa stack-operationer (push/pop)
- Testa att operationer fungerar med toppen av stacken
- Testa underflow (för få tal på stacken)

---

## Sammanfattning

Du har nu lärt dig:
- ✅ Red-Green-Refactor cykeln
- ✅ Skriva tester med Minitest
- ✅ Testa beteende istället för implementation
- ✅ Använda TDD för att bygga en klass steg för steg
- ✅ Refaktorera med tester som säkerhetsnät
- ✅ Felhantering och validering med TDD

**Viktigaste lärdomen:** Skriv testet *först*, implementera *sedan*, refaktorera *till sist*.

**Nästa steg:** I Assignment 1 använder vi TDD för att bygga vår Discord-bot!

## Resurser

- [Minitest Documentation](https://docs.seattlerb.org/minitest/)
- [Ruby Testing Guide](https://guides.rubyonrails.org/testing.html) (Rails-fokuserad men bra koncept)
- [Test-Driven Development by Example (bok av Kent Beck)](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [The Three Rules of TDD](http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd) (Uncle Bob Martin)
- [Ruby Math Module](https://ruby-doc.org/core-3.1.0/Math.html) (för stretch goals)
