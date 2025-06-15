require "nokogiri"
require "httparty"

class ScraperService
  attr_reader :url, :parsed_data

  def initialize(url)
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
      Rails.logger.error("Failed to fetch data from #{url}. Status code: #{response.code}")
      []
    end
  rescue => e
    Rails.logger.error("Error scraping #{url}: #{e.message}")
    []
  end

  private

  # Override this method in subclasses to implement specific scraping logic
  def parse_document(doc)
    # Example implementation - override in subclasses
    # doc.css("article").each do |article|
    #   @parsed_data << {
    #     title: article.css("h2").text.strip,
    #     content: article.css("p").text.strip,
    #     url: article.at_css("a")&.attr("href")
    #   }
    # end
    raise NotImplementedError, "Implement parse_document in a subclass"
  end
end 