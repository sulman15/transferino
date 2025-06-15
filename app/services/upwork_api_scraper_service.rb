require "upwork/api"
require "dotenv/load"
require "telegram/bot"

class UpworkApiScraperService
  attr_reader :parsed_data, :search_term, :config

  def initialize(search_term = "ruby on rails")
    @search_term = search_term
    @parsed_data = []
    
    # Load API configuration
    @config = {
      consumer_key: ENV["UPWORK_CONSUMER_KEY"],
      consumer_secret: ENV["UPWORK_CONSUMER_SECRET"],
      access_token: ENV["UPWORK_ACCESS_TOKEN"],
      access_secret: ENV["UPWORK_ACCESS_SECRET"],
      debug: false
    }
  end

  def scrape
    puts "Initializing Upwork API scraper..."
    
    # Check if we have all required credentials
    unless config_valid?
      puts "❌ Missing Upwork API credentials. Please set the following environment variables:"
      puts "   UPWORK_CONSUMER_KEY, UPWORK_CONSUMER_SECRET, UPWORK_ACCESS_TOKEN, UPWORK_ACCESS_SECRET"
      return []
    end
    
    begin
      # Initialize the Upwork API client
      client = Upwork::Api::Client.new(config)
      
      # Create the job search API
      jobs_api = client.jobs
      
      # Set up search parameters
      params = {
        q: search_term,
        paging: "0;50",  # Get up to 50 results
        sort: "create_time desc"  # Sort by most recent
      }
      
      puts "Searching for '#{search_term}' jobs on Upwork..."
      
      # Search for jobs
      response = jobs_api.search(params)
      
      # Check if we got a valid response
      if response && response["jobs"]
        puts "Found #{response["jobs"].size} jobs."
        
        # Process each job
        response["jobs"].each do |job|
          @parsed_data << {
            title: job["title"],
            link: "https://www.upwork.com/jobs/#{job["ciphertext"]}",
            description: job["snippet"],
            budget: extract_budget(job),
            skills: job["skills"]&.join(", ") || "Not specified",
            posted_time: Time.at(job["date_created"]).strftime("%Y-%m-%d %H:%M")
          }
        end
      else
        puts "No jobs found or invalid response."
      end
      
      @parsed_data
    rescue => e
      puts "❌ Error using Upwork API: #{e.message}"
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
  
  def config_valid?
    config[:consumer_key] && 
    config[:consumer_secret] && 
    config[:access_token] && 
    config[:access_secret]
  end
  
  def extract_budget(job)
    if job["budget"]
      "Fixed Price: $#{job["budget"]}"
    elsif job["hourly_budget_min"] && job["hourly_budget_max"]
      "Hourly Range: $#{job["hourly_budget_min"]}-$#{job["hourly_budget_max"]}"
    elsif job["hourly_budget_min"]
      "Hourly: $#{job["hourly_budget_min"]}+"
    elsif job["hourly_budget_max"]
      "Hourly: Up to $#{job["hourly_budget_max"]}"
    else
      "Budget not specified"
    end
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
    message += "<b>Posted:</b> #{job[:posted_time]}\n\n" if job[:posted_time]
    message += "<a href='#{job[:link]}'>View Job on Upwork</a>" if job[:link]
    
    message
  end
end 