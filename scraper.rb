# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find something on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'logger'
require 'uri'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL of the iframe (Dorset Council)
iframe_url = 'https://www.dorset.tas.gov.au/online-development-application-enquiry'

# Step 1: Fetch the iframe content
begin
  logger.info("Fetching iframe content from: #{iframe_url}")
  iframe_html = URI.open(iframe_url).read
  logger.info("Successfully fetched iframe content.")
rescue => e
  logger.error("Failed to fetch iframe content: #{e}")
  exit
end

# Step 2: Parse the iframe content using Nokogiri
doc = Nokogiri::HTML(iframe_html)

# Step 3: Extract the data (example: extracting all paragraphs)
# Adjust the tag and structure based on what you want to scrape
data = doc.css('p')  # Example: parsing all <p> tags (modify as necessary)

if data.empty?
  logger.warn("No data found in the iframe.")
else
  logger.info("Found the following data:")
  data.each do |item|
    logger.info("Data: #{item.text.strip}")
  end
end

# Step 4: Save the extracted data to a CSV file (optional)
CSV.open("scraped_data.csv", "wb") do |csv|
  csv << ['Data']  # Add headers if necessary
  data.each do |item|
    csv << [item.text.strip]
  end
end

logger.info("Scraping completed and data saved to scraped_data.csv.")

