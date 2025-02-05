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
require 'logger'
require 'sqlite3'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL of the iframe (Dorset Council)
iframe_url = 'https://eservices.dorset.tas.gov.au/eservice/dialog/daEnquiry/currentlyAdvertised.do?function_id=521&nodeNum=19534'

# Step 1: Fetch the iframe content using open-uri
begin
  logger.info("Fetching iframe content from: #{iframe_url}")
  iframe_html = open(iframe_url).read
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

# Step 4: Create or open the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create a table if it doesn't exist
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS scraped_data (
    id INTEGER PRIMARY KEY,
    data TEXT
  );
SQL

# Step 5: Insert the extracted data into the database
if data.empty?
  logger.warn("No data found in the iframe.")
else
  logger.info("Found the following data:")
  data.each do |item|
    logger.info("Data: #{item.text.strip}")
    # Insert data into the database
    db.execute("INSERT INTO scraped_data (data) VALUES (?)", [item.text.strip])
  end
end

logger.info("Scraping completed and data saved to data.sqlite.")
