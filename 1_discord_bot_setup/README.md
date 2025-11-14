# Uppgift 1: Discord Bot Setup

## Översikt

I denna uppgift ska du sätta upp en Discord-bot och få den att svara på `!hello`. Detta är en **teknisk förutsättning** för resten av kursen - ingen TDD eller OOP än, bara att få bot:en att fungera.

## Förutsättningar

- Uppgift 0 klar (TDD fundamentals med Dice-klassen)
- Discord-konto
- Ruby 3.0+ installerat

## ⚠️ VIKTIGT: Skapa Din Projektmapp

**Skapa en ny mapp där du kommer arbeta med bot:en under HELA kursen.**

```bash
# Gå till din hemkatalog (eller valfri plats)
cd ~

# Skapa en mapp för din bot
mkdir my_discord_bot
cd my_discord_bot

# Initiera git (valfritt men rekommenderat)
git init
```

**Denna mapp (`my_discord_bot`) kommer du använda för ALLA uppgifter!** I framtida uppgifter lägger vi till `lib/` och `test/` mappar här.

---

## Del 1: Skapa Discord Bot

### Steg 1: Discord Developer Portal

1. Gå till https://discord.com/developers/applications
2. Klicka "New Application"
3. Ge den ett namn (t.ex. "MinRubyBot")
4. Klicka "Create"

### Steg 2: Konfigurera Bot

1. Gå till "Bot" tab i sidomenyn
2. Scrolla ner till "Privileged Gateway Intents"
3. Aktivera:
   - ✅ "Server Members Intent"
   - ✅ "Message Content Intent" **(viktigt!)**

### Steg 3: Kopiera Token

1. Under "TOKEN", klicka "Reset Token" (om ingen token syns)
2. Klicka "Copy"
3. ⚠️ **VIKTIGT:** Dela ALDRIG denna token! Den är som ett lösenord.

### Steg 4: Bjud in Bot till Din Server

**(Skapa först en testserver om du inte har en - klicka "+" i Discord serverlistan)**
1. Gå till "OAuth2" → "URL Generator" i sidomenyn
2. Under "SCOPES": kryssa i `bot`
3. Under "BOT PERMISSIONS":
   - ✅ Send Messages
   - ✅ Read Message History
   - ✅ View Channels
4. Kopiera URL:en som genereras längst ner
5. Öppna URL:en i en ny flik
6. Välj din testserver
7. Klicka "Continue" → "Authorize"
8. Bot:en är nu i din server! ✅

---

## Del 2: Setup Ruby-Projekt

### Steg 1: Skapa .env Fil

Skapa `.env` i din `my_discord_bot` mapp (ersätt `din_token_här` med din token):

```
DISCORD_BOT_TOKEN=din_token_här
```

⚠️ **Hårdkoda ALDRIG tokens i kod!** Använd alltid miljövariabler.

### Steg 2: Skapa .gitignore

Skapa `.gitignore` (förhindrar att token commitas till Git):

```
.env
```

### Steg 3: Skapa Gemfile

Skapa `Gemfile`:

```ruby
source 'https://rubygems.org'

gem 'discordrb', '~> 3.5'
gem 'dotenv', '~> 2.8'
gem 'minitest-reporters', '~> 1.6'  # Better test output with colors
```

**Installera gems:**
```bash
bundle install
```

**Vad är minitest-reporters?**
- Ger färgglad, lättläst testoutput istället för bara prickar (`.`)
- Visar exakt vilka tester som körs och passerar
- Gör TDD-cykeln mer motiverande!

### Steg 4: Verifiera Setup

Skapa en fil `test_setup.rb` för att testa att allt fungerar:

```ruby
require 'discordrb'
require 'dotenv/load'

token = ENV['DISCORD_BOT_TOKEN']

if token.nil? || token.empty?
  puts "❌ DISCORD_BOT_TOKEN är inte satt i .env filen!"
  exit 1
end

puts "✅ Token hittad!"
puts "✅ discordrb gem installerad!"
puts "✅ Setup klar! Du kan börja bygga din bot."
```

**Kör:**
```bash
ruby test_setup.rb
```

Du ska se:
```
✅ Token hittad!
✅ discordrb gem installerad!
✅ Setup klar! Du kan börja bygga din bot.
```

---

## Del 3: Skapa Din Första Bot

Skapa `bot.rb` som svarar på `!hello`:

```ruby
require 'discordrb'
require 'dotenv/load'

# Hämta token från miljövariabel
token = ENV['DISCORD_BOT_TOKEN']

if token.nil? || token.empty?
  puts "❌ DISCORD_BOT_TOKEN är inte satt!"
  puts "Skapa en .env fil med: DISCORD_BOT_TOKEN=din_token"
  exit 1
end

# Skapa bot med nödvändiga intents
bot = Discordrb::Bot.new(
  token: token,
  intents: [:server_messages]
)

# Hantera meddelanden
bot.message do |event|
  # Ignorera bot:ens egna meddelanden
  next if event.user.bot_account?

  # Svara på !hello
  if event.content.strip.downcase == "!hello"
    event.respond("Hello! I'm alive! 🤖")
  end
end

# Logga när bot:en startar
bot.ready do
  puts "✅ Bot inloggad som: #{bot.profile.username}"
  puts "📡 Bot är online och lyssnar på kommandon!"
  puts "💬 Testa: !hello"
end

# Starta bot:en
puts "🚀 Startar bot..."
bot.run
```

### Kör Din Bot!

```bash
ruby bot.rb
# Du ska se: 🚀 Startar bot... ✅ Bot inloggad som: MinRubyBot
```

**Gå till Discord** och skriv `!hello` - bot:en ska svara! 🎉

**Stoppa bot:en:** Tryck `Ctrl+C`

---

## Vanliga Problem

### Problem: "Invalid token"

**Lösning:**
- Kontrollera att token i `.env` är korrekt kopierad
- Ingen extra whitespace före/efter token
- Token ska vara en lång sträng med bokstäver, siffror och punkter

### Problem: Bot svarar inte

**Lösning:**
- Kontrollera att "Message Content Intent" är aktiverat i Discord Developer Portal
- Kontrollera att bot:en har rätt permissions (Send Messages, Read Message History)
- Testa med exakt `!hello` (lowercase, med utropstecken)

### Problem: "Cannot find module 'discordrb'"

**Lösning:**
- Kör `bundle install` igen
- Kontrollera att du är i rätt mapp

---

## Grattis! 🎉

Du har nu en fungerande Discord-bot med säker token-hantering och en projektmapp för resten av kursen.

**Nästa steg (Uppgift 2):** Vi börjar med TDD och bygger en riktig `Command` klass-struktur med mocks, OOP-grunderna, och keyword arguments.

---

## Resurser

- [Discord Developer Portal](https://discord.com/developers/applications)
- [discordrb Documentation](https://www.rubydoc.info/gems/discordrb)
- [Discord Bot Best Practices](https://discord.com/developers/docs/topics/community-resources#bots-and-apps)
- [dotenv gem](https://github.com/bkeepers/dotenv)
