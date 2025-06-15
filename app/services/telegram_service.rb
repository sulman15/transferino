require "telegram/bot"

class TelegramService
  attr_reader :token, :channel_id

  def initialize
    config = YAML.load_file(Rails.root.join("config", "telegram.yml"))[Rails.env]
    @token = config["bot_token"]
    @channel_id = config["channel_id"]
  end

  def send_message(text)
    return false if text.blank?

    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_message(
        chat_id: channel_id,
        text: text,
        parse_mode: "HTML"
      )
    end
    true
  rescue => e
    Rails.logger.error("Error sending Telegram message: #{e.message}")
    false
  end

  def send_photo(photo_url, caption = nil)
    return false if photo_url.blank?

    Telegram::Bot::Client.run(token) do |bot|
      bot.api.send_photo(
        chat_id: channel_id,
        photo: photo_url,
        caption: caption,
        parse_mode: "HTML"
      )
    end
    true
  rescue => e
    Rails.logger.error("Error sending Telegram photo: #{e.message}")
    false
  end

  def format_news_message(news_item)
    message = ""
    message += "<b>#{news_item[:title]}</b>\n\n" if news_item[:title].present?
    message += "#{news_item[:summary]}\n\n" if news_item[:summary].present?
    message += "Published: #{news_item[:published_at]}\n" if news_item[:published_at].present?
    message += "<a href='#{news_item[:link]}'>Read more</a>" if news_item[:link].present?
    message
  end
end 