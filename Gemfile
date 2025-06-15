source "https://rubygems.org"

ruby "3.0.7"

# Rails core
gem "rails", "~> 7.0.8"
gem "mysql2", "~> 0.5"
gem "puma", "~> 5.0"

# Assets and frontend
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Web scraping
gem "nokogiri", "~> 1.15"
gem "httparty", "~> 0.21.0"

# Telegram integration
gem "telegram-bot-ruby", "~> 1.0"

# Background processing
gem "sidekiq", "~> 7.1"
gem "whenever", "~> 1.0", require: false

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "logger", "~> 1.7.0"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
end 