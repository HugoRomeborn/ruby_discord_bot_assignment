require 'discordrb'
require 'dotenv/load'
require_relative 'lib/hello_command'
require_relative 'lib/ping_command'
require_relative 'lib/info_command'

# Hämta token från miljövariabel
token = ENV['DISCORD_BOT_TOKEN']

if token.nil? || token.empty?
  puts "❌ DISCORD_BOT_TOKEN är inte satt!"
  puts "Skapa en .env fil med: DISCORD_BOT_TOKEN=din_token"
  exit 1
end

# Skapa bot med nödvändiga intents
bot = Discordrb::Bot.new(token: token, intents: [:server_messages])

hello_command = HelloCommand.new
ping_command = PingCommand.new
info_command = InfoCommand.new

bot.message do |event|
  # Ignorera bot:ens egna meddelanden
  next if event.user.bot_account?

  content = event.content.strip.downcase

  # Kolla om meddelandet är ett kommando
  case content
  when "!hello"
    hello_command.execute(event)
  when "!ping"
    ping_command.execute(event)
  when "!info"
    info_command.execute(event)
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