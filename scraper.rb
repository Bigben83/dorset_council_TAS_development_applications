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

# Step 3: Create or open the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Step 4: Drop the table if it exists and create it with the correct structure
db.execute <<-SQL
  DROP TABLE IF EXISTS scraped_data;
  CREATE TABLE scraped_data (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_received TEXT,
    address TEXT,
    council_reference TEXT
  );
SQL

# Step 5: Extract and categorize the data
# Find all <p> elements with <span> children
data = doc.css('p')

# Define variables for storing extracted data
description = ''
date_received = ''
address = ''
council_reference = ''

# Iterate through each <p> tag and extract the key-value pairs
data.each do |p|
  spans = p.css('span')
  if spans.length == 2
    key = spans[0].text.strip
    value = spans[1].text.strip

    # Categorize based on the key
    case key
    when 'Type of Work'
      description = value
    when 'Date Lodged'
      date_received = value
    when 'Application No.'
      council_reference = value
    end
  end
end

# Extract the address from the <h4><a> tag
address_tag = doc.at_css('h4 a')
address = address_tag ? address_tag.text.strip : ''

# Step 6: Insert the categorized data into the database
db.execute("INSERT INTO scraped_data (description, date_received, address, council_reference)
            VALUES (?, ?, ?, ?)",
            [description, date_received, address, council_reference])

logger.info("Scraping completed and data saved to data.sqlite.")
