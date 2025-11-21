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