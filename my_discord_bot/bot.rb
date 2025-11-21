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

puts "🚀 Startar bot..."
bot.run