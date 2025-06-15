# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Set the output to a log file
set :output, "log/cron.log"

# Set environment
set :environment, ENV["RAILS_ENV"] || "development"

# Run the news scraper every 3 hours
every 3.hours do
  runner "ScrapeAndSendJob.perform_later('NewsScraperService')"
end

# You can add more scrapers with different schedules
# For example, to run a different scraper daily at 8 AM:
# every 1.day, at: "8:00 am" do
#   runner "ScrapeAndSendJob.perform_later('AnotherScraperService')"
# end 