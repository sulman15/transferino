require "rss"
require "open-uri"
require "dotenv/load"
require "telegram/bot"

class UpworkRssScraperService
  attr_reader :url, :parsed_data, :search_term

  def initialize(search_term = "ruby on rails")
    @search_term = search_term
    @parsed_data = []
    
    # Build the RSS URL
    @url = build_url
  end

  def scrape
    puts "Scraping data from #{url}..."
    
    begin
      # Open and parse the RSS feed
      URI.open(url) do |rss|
        feed = RSS::Parser.parse(rss)
        puts "Feed title: #{feed.channel.title}"
        puts "Found #{feed.items.size} items in feed"
        
        feed.items.each do |item|
          job = {
            title: item.title,
            link: item.link,
            description: clean_description(item.description),
            published_at: item.pubDate.strftime("%Y-%m-%d %H:%M")
          }
          
          # Extract budget and skills from description if possible
          job[:budget] = extract_budget(item.description)
          job[:skills] = extract_skills(item.description)
          
          @parsed_data << job
        end
      end
      
      puts "Processed #{@parsed_data.size} jobs."
      @parsed_data
    rescue OpenURI::HTTPError => e
      puts "HTTP Error: #{e.message}"
      []
    rescue => e
      puts "Error scraping #{url}: #{e.message}"
      []
    end
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
      @parsed_data.each do |job|
        message = format_message(job)
        
        Telegram::Bot::Client.run(bot_token) do |bot|
          bot.api.send_message(
            chat_id: channel_id,
            text: message,
            parse_mode: "HTML",
            disable_web_page_preview: false
          )
        end
        
        # Add a small delay between messages to avoid hitting rate limits
        sleep(1)
      end
      
      puts "✅ Successfully sent #{@parsed_data.size} jobs to Telegram"
      true
    rescue => e
      puts "❌ Error sending to Telegram: #{e.message}"
      false
    end
  end

  private

  def build_url
    # Encode the search term for URL
    encoded_term = URI.encode_www_form_component(@search_term)
    "https://www.upwork.com/ab/feed/jobs/rss?q=#{encoded_term}&sort=recency"
  end
  
  def clean_description(html)
    # Remove HTML tags and clean up the description
    description = html.gsub(/<\/?[^>]*>/, "")
    description = description.gsub(/&nbsp;/, " ")
    description = description.gsub(/&amp;/, "&")
    description = description.gsub(/&lt;/, "<")
    description = description.gsub(/&gt;/, ">")
    description = description.gsub(/\s+/, " ").strip
    description
  end
  
  def extract_budget(description)
    # Try to extract budget information from the description
    budget_match = description.match(/Budget: \$([0-9,.]+)|Fixed-Price - Budget: \$([0-9,.]+)|Hourly Range: \$([0-9.,]+)-\$([0-9.,]+)/)
    return "Budget not specified" unless budget_match
    
    if budget_match[1]
      "Fixed Price: $#{budget_match[1]}"
    elsif budget_match[2]
      "Fixed Price: $#{budget_match[2]}"
    elsif budget_match[3] && budget_match[4]
      "Hourly Range: $#{budget_match[3]}-$#{budget_match[4]}"
    else
      "Budget not specified"
    end
  end
  
  def extract_skills(description)
    # Try to extract skills from the description
    skills_match = description.match(/Skills: ([^<]+)/)
    skills_match ? skills_match[1].strip : "Skills not specified"
  end

  def format_message(job)
    message = ""
    message += "<b>#{job[:title]}</b>\n\n" if job[:title]
    
    # Truncate description if it's too long
    if job[:description] && job[:description].length > 300
      message += "#{job[:description][0..300]}...\n\n"
    else
      message += "#{job[:description]}\n\n" if job[:description]
    end
    
    message += "<b>Budget:</b> #{job[:budget]}\n" if job[:budget]
    message += "<b>Skills:</b> #{job[:skills]}\n" if job[:skills]
    message += "<b>Posted:</b> #{job[:published_at]}\n\n" if job[:published_at]
    message += "<a href='#{job[:link]}'>View Job on Upwork</a>" if job[:link]
    
    message
  end
end 