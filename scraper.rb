require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'uri'

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

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create a table to store the categorized data (drop and recreate it for each run)
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS scraped_data (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_received TEXT,
    address TEXT,
    council_reference TEXT
  );
SQL

# Step 4: Extract and categorize the data
# Find all entries (e.g., the <p> elements within the list of advertised applications)
entries = doc.css('p')  # This may need adjustment based on the actual HTML structure

# Iterate through the entries and extract data for each
entries.each do |entry|
  # Define variables for storing extracted data for each entry
  description = ''
  date_received = ''
  address = ''
  council_reference = ''

  spans = entry.css('span')
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

  # Extract the address from the <h4><a> tag (if any)
  address_tag = entry.at_css('h4 a')
  address = address_tag ? address_tag.text.strip : ''

  # Step 5: Insert the extracted data into the database for each entry
  db.execute("INSERT INTO scraped_data (description, date_received, address, council_reference)
              VALUES (?, ?, ?, ?)",
              [description, date_received, address, council_reference])

  logger.info("Data for application #{council_reference} saved to database.")
end

logger.info("Scraping completed and all data saved to data.sqlite.")
