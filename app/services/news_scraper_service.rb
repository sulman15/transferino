class NewsScraperService < ScraperService
  def initialize(url = "https://example-news-site.com")
    super(url)
  end

  private

  def parse_document(doc)
    # This is an example implementation - adjust selectors based on the target website
    doc.css("article.news-item").each do |article|
      title = article.at_css("h2")&.text&.strip
      summary = article.at_css(".summary")&.text&.strip
      link = article.at_css("a.read-more")&.attr("href")
      
      # Make sure link is absolute
      link = URI.join(url, link).to_s if link && !link.start_with?("http")
      
      published_at = article.at_css(".date")&.text&.strip
      
      @parsed_data << {
        title: title,
        summary: summary,
        link: link,
        published_at: published_at
      }
    end
  end
end 