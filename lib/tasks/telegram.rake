namespace :telegram do
  desc "Test Telegram bot connection"
  task test_connection: :environment do
    telegram = TelegramService.new
    result = telegram.send_message("Test message from Transferino app!")
    
    if result
      puts "✅ Message sent successfully! Check your Telegram channel."
    else
      puts "❌ Failed to send message. Check your bot token and channel ID."
    end
  end
end 