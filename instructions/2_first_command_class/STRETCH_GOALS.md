# Stretch Goals - Uppgift 2: First Command Class

Dessa är **valfria** utmaningar för dig som vill öva mer på TDD och Discord-bot kommandon.

---

## 1. DiceCommand - Testa Slumpmässighet

**Din uppgift:** Skapa ett `!dice` kommando som rullar en tärning (1-6).

### TDD-Process:

**🔴 Skriv tester** i `test/test_dice_command.rb`
- Test att kommandot returnerar ett nummer mellan 1 och 6
- Test att resultatet är ett heltal
- **Tips:** Kör testet flera gånger för att verifiera slumpmässighet

**Testutmaning:** Hur testar man slumpmässighet?

```ruby
def test_dice_returns_number_between_1_and_6
  command = DiceCommand.new

  # Kör 100 gånger för att verifiera range
  100.times do
    mock_event = MockEvent.new(content: "!dice")
    command.execute(mock_event)

    # Extrahera nummer från svaret (t.ex. "Du rullade: 4")
    response = mock_event.responses.first
    number = response.match(/\d+/)[0].to_i

    assert_includes 1..6, number
  end
end
```

**🟢 Implementera** `lib/dice_command.rb`
- Använd `rand(1..6)` för att generera slumptal
- Svara med t.ex: "Du rullade: 4"

**🔵 Koppla in** kommandot i `bot.rb`

---

## 2. EchoCommand - Extrahera Argument

Skapa ett kommando som ekar tillbaka användarens meddelande.

**Exempel:**
- User: `!echo Hello world`
- Bot: `Echo: Hello world`

**Utmaning:** Hur hanterar du text efter `!echo`?

**Tips:**
```ruby
content = event.content  # "!echo Hello world"
text = content.sub("!echo", "").strip  # "Hello world"
```

**TDD-Process:**
1. Skriv test i `test/test_echo_command.rb`
2. Implementera `lib/echo_command.rb`
3. Testa edge cases:
   - Vad händer om användaren bara skriver `!echo`?
   - Vad händer med flera mellanslag?

---

## 3. UserInfoCommand - Använda MockUser

Skapa ett kommando som visar information om användaren.

**Exempel:**
- User: `!userinfo`
- Bot: `👤 Användarnamn: TestUser (ID: 123456789)`

**Tips:** Använd `event.user.name` och `event.user.id`

**Testutmaning:** Hur testar du att rätt användarnamn visas?

```ruby
def test_userinfo_shows_username
  mock_user = MockUser.new(name: "Alice", id: 999)
  mock_event = MockEvent.new(content: "!userinfo", user: mock_user)

  command = UserInfoCommand.new
  command.execute(mock_event)

  response = mock_event.responses.first
  assert_includes response, "Alice"
  assert_includes response, "999"
end
```

Detta tränar på att använda mock-objekt med custom data!

---

## 4. SayCommand - Argument med TDD

Skapa ett `!say <text>` kommando som får bot:en att säga något.

**Exempel:**
- User: `!say Ruby är coolt!`
- Bot: `Ruby är coolt!`

**TDD-Process:**
- Testa att kommandot extraherar rätt text
- Testa edge cases:
  - Tom text
  - Bara `!say`
  - Extra mellanslag

**Diskussionsfråga:** Ska detta kommando returnera felmeddelande om ingen text anges, eller bara ingenting?

---

## 5. Case-insensitive Kommandon

Gör så att `!HELLO`, `!Hello`, och `!hello` alla fungerar.

**Var ska denna logik finnas?**
- I `bot.rb`? (där vi matchar kommandon)
- I varje Command klass?

**Diskussion:** Vilken lösning är bäst? Varför?

**Hint:** Du har redan gjort detta i `bot.rb` med `.downcase` - men tänk på när detta inte skulle fungera (kommando med argument som ska vara case-sensitive).

---

## 6. HelpCommand - Lista Alla Kommandon

Skapa ett `!help` kommando som listar alla tillgängliga kommandon.

**Exempel:**
```
!help
Bot svarar:
📚 Tillgängliga kommandon:
- !hello - Säger hej!
- !ping - Pingar bot:en
- !info - Visar bot-information
- !dice - Rullar en tärning
```

**Utmaning:** Hur får du tag på alla kommandon och deras beskrivningar?

**Tips:**
```ruby
# I bot.rb, skapa en array av alla kommandon
commands = [hello_command, ping_command, info_command]

# Hur kan HelpCommand få tillgång till denna array?
# (Detta introducerar konceptet dependency injection!)
```

---

## 7. CoinFlipCommand - Boolean Slump

Skapa ett `!flip` kommando som slår mynt.

**Exempel:**
- User: `!flip`
- Bot: `🪙 Du fick: Krona!` (eller `Klave!`)

**Testutmaning:** Hur testar du att båda utfallen kan hända?

```ruby
def test_coinflip_returns_both_outcomes
  command = CoinFlipCommand.new
  results = []

  # Kör 100 gånger
  100.times do
    mock_event = MockEvent.new
    command.execute(mock_event)
    results << mock_event.responses.first
  end

  # Verifiera att båda "Krona" och "Klave" dyker upp
  assert results.any? { |r| r.include?("Krona") }
  assert results.any? { |r| r.include?("Klave") }
end
```

---

## Vilka Stretch Goals Tränar Vad?

- **DiceCommand** - Slumpmässighet, testa ranges
- **EchoCommand** - String manipulation, argument extraction
- **UserInfoCommand** - Använda mock-objekt med custom data
- **SayCommand** - Edge case testing, error handling
- **Case-insensitive** - Designbeslut, var logik ska finnas
- **HelpCommand** - Dependency injection (försmak av Uppgift 6)
- **CoinFlipCommand** - Boolean randomness, test coverage

Lycka till! 🎉
