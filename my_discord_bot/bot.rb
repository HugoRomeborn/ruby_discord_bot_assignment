require 'discordrb'
require 'dotenv/load'
require_relative 'lib/command'
require_relative 'lib/dice_command'
require_relative 'lib/echo_command'
require_relative 'lib/text_command'


# Hämta token från miljövariabel
token = ENV['DISCORD_BOT_TOKEN']

if token.nil? || token.empty?
  puts "❌ DISCORD_BOT_TOKEN är inte satt!"
  puts "Skapa en .env fil med: DISCORD_BOT_TOKEN=din_token"
  exit 1
end

# Skapa bot med nödvändiga intents
bot = Discordrb::Bot.new(token: token, intents: [:server_messages])

hello_command = TextCommand.new(name: "hello", description: "Säger hej!", text: "Hello!")
ping_command = TextCommand.new(name: "ping", description: "Svarar med pong", text: "Pong!")
info_command = TextCommand.new(name: "info", description: "Informerar om bot", text: "Jag är en bot som hjälper denna server att fungera.")
dice_command = DiceCommand.new
echo_command = EchoCommand.new

bot.message do |event|
  # Ignorera bot:ens egna meddelanden
  next if event.user.bot_account?

  content = event.content.strip.downcase.split

  # Kolla om meddelandet är ett kommando
  case content[0]
  when "!hello"
    
    hello_command.execute(event)
  when "!ping"
    ping_command.execute(event)
  when "!info"
    info_command.execute(event)
  when "!dice"
    dice_command.execute(event)
  when "!echo"
    echo_command.execute(event)
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