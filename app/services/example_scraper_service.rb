require "nokogiri"
require "httparty"
require "yaml"
require "dotenv/load" # Load environment variables from .env file

class ExampleScraperService
  attr_reader :url, :parsed_data

  def initialize(url = "https://news.ycombinator.com/")
    @url = url
    @parsed_data = []
  end

  def scrape
    response = HTTParty.get(url)
    
    if response.success?
      doc = Nokogiri::HTML(response.body)
      parse_document(doc)
      @parsed_data
    else
      puts "Failed to fetch data from #{url}. Status code: #{response.code}"
      []
    end
  rescue => e
    puts "Error scraping #{url}: #{e.message}"
    []
  end

  def send_to_telegram
    return if @parsed_data.empty?
    
    begin
      # Get token and channel ID from environment variables
      bot_token = ENV["TELEGRAM_BOT_TOKEN"]
      channel_id = ENV["TELEGRAM_CHANNEL_ID"]
      
      # Fall back to config file if environment variables are not set
      if bot_token.nil? || channel_id.nil?
        # Load configuration from YAML file
        config_file = File.join(File.dirname(__FILE__), "..", "..", "config", "telegram.yml")
        config = YAML.load_file(config_file)["development"]
        
        bot_token ||= config["bot_token"]
        channel_id ||= config["channel_id"]
      end
      
      # Send each item to Telegram
      @parsed_data.each do |item|
        message = format_message(item)
        
        Telegram::Bot::Client.run(bot_token) do |bot|
          bot.api.send_message(
            chat_id: channel_id,
            text: message,
            parse_mode: "HTML"
          )
        end
        
        # Add a small delay between messages to avoid hitting rate limits
        sleep(1)
      end
      
      puts "✅ Successfully sent #{@parsed_data.size} items to Telegram"
      true
    rescue => e
      puts "❌ Error sending to Telegram: #{e.message}"
      false
    end
  end

  private

  def parse_document(doc)
    # Example: Scraping Hacker News
    doc.css(".athing").each_with_index do |item, index|
      break if index >= 10 # Limit to 10 items
      
      title_element = item.at_css(".titleline a")
      next unless title_element
      
      title = title_element.text.strip
      link = title_element["href"]
      
      # Get the subtext which contains points, author and time
      subtext = item.next_element.at_css(".subtext")
      next unless subtext
      
      points = subtext.at_css(".score")&.text&.strip || "0 points"
      author = subtext.at_css(".hnuser")&.text&.strip || "Unknown"
      time = subtext.at_css(".age")&.text&.strip || "Unknown time"
      
      @parsed_data << {
        title: title,
        link: link,
        points: points,
        author: author,
        time: time
      }
    end
  end

  def format_message(item)
    message = ""
    message += "<b>#{item[:title]}</b>\n\n"
    message += "Points: #{item[:points]}\n"
    message += "Author: #{item[:author]}\n"
    message += "Posted: #{item[:time]}\n\n"
    message += "<a href='#{item[:link]}'>Read more</a>"
    message
  end
end
 