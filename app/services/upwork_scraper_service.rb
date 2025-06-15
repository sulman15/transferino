require "nokogiri"
require "httparty"
require "yaml"
require "dotenv/load"

class UpworkScraperService
  attr_reader :url, :parsed_data, :search_term, :category

  def initialize(search_term = nil, category = nil)
    @search_term = search_term
    @category = category
    @parsed_data = []
    
    # Build the URL based on search parameters
    @url = build_url
  end

  def scrape
    # Set up headers to mimic a browser
    headers = {
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.5",
      "Referer" => "https://www.upwork.com/",
      "DNT" => "1",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1"
    }

    puts "Scraping data from #{url}..."
    
    begin
      response = HTTParty.get(url, headers: headers)
      
      if response.success?
        puts "Successfully retrieved page."
        doc = Nokogiri::HTML(response.body)
        parse_document(doc)
        puts "Found #{@parsed_data.size} jobs."
        @parsed_data
      else
        puts "Failed to fetch data from #{url}. Status code: #{response.code}"
        puts "Response body: #{response.body[0..500]}..." if response.body
        []
      end
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
    base_url = "https://www.upwork.com/nx/jobs/search/"
    params = []
    
    params << "q=#{URI.encode_www_form_component(@search_term)}" if @search_term
    params << "category2_uid=#{URI.encode_www_form_component(@category)}" if @category
    
    if params.empty?
      base_url
    else
      "#{base_url}?#{params.join('&')}"
    end
  end

  def parse_document(doc)
    # Upwork job listings are typically in sections with specific classes
    # This is a generic approach and might need adjustments based on actual HTML structure
    job_sections = doc.css('section[data-test="job-tile"]')
    
    if job_sections.empty?
      puts "No job sections found. HTML structure might have changed."
      puts "First 1000 characters of HTML: #{doc.to_html[0..1000]}"
      return
    end
    
    job_sections.each do |section|
      begin
        # Extract job details
        title_element = section.at_css('h2[data-test="job-title"], .job-title')
        next unless title_element
        
        title = title_element.text.strip
        
        # Get the job link
        link_element = title_element.parent
        link = link_element['href'] if link_element.name == 'a'
        
        # If link is relative, make it absolute
        if link && !link.start_with?('http')
          link = "https://www.upwork.com#{link}"
        end
        
        # Extract job description
        description_element = section.at_css('.job-description, [data-test="job-description"]')
        description = description_element ? description_element.text.strip : "No description available"
        
        # Extract budget/rate
        budget_element = section.at_css('.js-budget, [data-test="budget"]')
        budget = budget_element ? budget_element.text.strip : "Budget not specified"
        
        # Extract skills
        skills_elements = section.css('.js-skills, [data-test="skill"]')
        skills = skills_elements.map(&:text).join(", ")
        
        # Extract posting time
        time_element = section.at_css('.js-posted-time, [data-test="posted-on"]')
        posted_time = time_element ? time_element.text.strip : "Unknown time"
        
        @parsed_data << {
          title: title,
          link: link,
          description: description,
          budget: budget,
          skills: skills,
          posted_time: posted_time
        }
      rescue => e
        puts "Error parsing job section: #{e.message}"
      end
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