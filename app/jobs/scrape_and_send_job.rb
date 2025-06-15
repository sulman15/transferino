class ScrapeAndSendJob < ApplicationJob
  queue_as :default

  def perform(scraper_class_name, url = nil)
    # Initialize the scraper
    scraper_class = scraper_class_name.constantize
    scraper = url.present? ? scraper_class.new(url) : scraper_class.new
    
    # Scrape the data
    data = scraper.scrape
    
    return if data.blank?
    
    # Send to Telegram
    telegram = TelegramService.new
    
    data.each do |item|
      message = telegram.format_news_message(item)
      telegram.send_message(message)
      
      # Add a small delay between messages to avoid hitting rate limits
      sleep(1)
    end
  end
end 