# Transferino

A Ruby application for scraping data from websites and sending it to Telegram channels.

## Features

- Web scraping using Nokogiri and HTTParty
- Telegram integration for sending messages to channels
- Formatted messages with HTML styling
- Example scraper for Hacker News
- Environment variables support for sensitive information

## Requirements

- Ruby 3.0.7
- Telegram Bot Token
- Telegram Channel ID

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/sulman15/transferino.git
   cd transferino
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Configure your Telegram bot:
   - Create a bot using BotFather on Telegram
   - Create a Telegram channel and add your bot as an administrator
   - Copy `.env.sample` to `.env` and update with your credentials:
     ```
     cp .env.sample .env
     ```
   - Edit `.env` with your bot token and channel ID:
     ```
     TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
     TELEGRAM_CHANNEL_ID=your_telegram_channel_id_here
     ```

4. Test the Telegram integration:
   ```
   ruby bin/simple_telegram_test
   ```

## Running the Scraper

To run the example Hacker News scraper:

```
ruby bin/run_scraper
```

This will:
1. Scrape the top 10 posts from Hacker News
2. Format them as messages with titles, points, authors, and links
3. Send them to your configured Telegram channel

## Creating a Custom Scraper

To create a scraper for a different website:

1. Copy the example scraper as a starting point:
   ```
   cp app/services/example_scraper_service.rb app/services/your_custom_scraper.rb
   ```

2. Modify the `parse_document` method to extract data from your target website
3. Adjust the `format_message` method if needed
4. Update the URL in the `initialize` method

## Scheduling Regular Scraping

For scheduled scraping, you can:

1. Set up a cron job to run the scraper at regular intervals
2. Use the whenever gem for more Ruby-like scheduling syntax

## Project Structure

- `app/services/` - Contains the scraper services
- `bin/` - Scripts for running and testing
- `config/` - Configuration files
- `.env` - Environment variables for sensitive information

## Security

Sensitive information like API tokens and channel IDs should be stored in the `.env` file, which is excluded from Git. Never commit your actual tokens to the repository.

## Contributing

Contributions are welcome! Feel free to submit a pull request.