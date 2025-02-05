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

# Step 5: Extract and categorize the data
# Find all <div> elements containing the <p> with class="rowDataOnly"
entries = doc.css('div').select { |div| div.at_css('.rowDataOnly') }

entries.each do |entry|
  # Extract the address from the <h4><a> tag above each entry
  address_tag = entry.at_css('h4 a')
  address = address_tag ? address_tag.text.strip : ''

  # Define variables for storing extracted data for each entry
  description = ''
  date_received = ''
  council_reference = ''

  # Extract the key-value pairs from each <p class="rowDataOnly">
  entry.css('.rowDataOnly').each do |p|
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

  # Step 6: Ensure the entry does not already exist before inserting
  existing_entry = db.execute("SELECT * FROM scraped_data WHERE council_reference = ? AND address = ?", [council_reference, address])
  
  if existing_entry.empty? # Only insert if the entry doesn't already exist
    db.execute("INSERT INTO scraped_data (description, date_received, address, council_reference)
                VALUES (?, ?, ?, ?)",
                [description, date_received, address, council_reference])

    logger.info("Data for application #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for application #{council_reference} found. Skipping insertion.")
  end
end

logger.info("Scraping completed and all data saved to data.sqlite.")
