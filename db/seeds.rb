require "csv"

# Create a test user for development
if Rails.env.development?
  admin = User.find_or_create_by!(email_address: "admin@codeforamerica.org") do |user|
    user.password = "password"
    puts "Created test user: admin@codeforamerica.org / password"
  end

  # Create Salt Lake City site
  slc = Site.find_or_create_by!(
    name: "SLC.gov",
    location: "Salt Lake City, UT",
    primary_url: "https://www.slc.gov/",
    user: admin
  )
  puts "Created site: #{slc.name}"

  # Create San Rafael site
  san_rafael = Site.find_or_create_by!(
    name: "The City with a Mission",
    location: "San Rafael, CA",
    primary_url: "https://www.cityofsanrafael.org/",
    user: admin
  )
  puts "Created site: #{san_rafael.name}"

  def process_csv_documents(site, csv_path)
    return unless File.exist?(csv_path)

    documents = []
    skipped = 0

    CSV.foreach(csv_path, headers: true) do |row|
      # Encode URL while preserving basic URL structure
      encoded_url = URI.encode_www_form_component(row["url"])
        .gsub("%3A", ":")  # Restore colons
        .gsub("%2F", "/")  # Restore forward slashes

      # Parse file size (remove KB suffix and convert to float)
      file_size = row["file_size"]&.gsub("KB", "")&.strip&.to_f

      documents << {
        url: encoded_url,
        file_name: row["file_name"],
        file_size: file_size,
        author: row["author"],
        subject: row["subject"],
        pdf_version: row["version"],
        keywords: row["keywords"],
        creation_date: row["creation_date"],
        modification_date: row["last_modified_date"],
        producer: row["producer"],
        source: row["source"],
        number_of_pages: row["number_of_pages"]&.to_i
      }
    rescue URI::InvalidURIError => e
      puts "Skipping invalid URL: #{row["url"]}"
      puts "Error: #{e.message}"
      skipped += 1
    end

    site.discover_documents!(documents)
    puts "Created #{documents.size} documents for #{site.name}"
    puts "Skipped #{skipped} documents due to invalid URLs" if skipped > 0
  end

  # Process Salt Lake City documents
  puts "\nProcessing Salt Lake City documents..."
  slc_csv_path = Rails.root.join("db", "seeds", "salt_lake_city.csv")
  process_csv_documents(slc, slc_csv_path)

  # Process San Rafael documents
  puts "\nProcessing San Rafael documents..."
  sr_csv_path = Rails.root.join("db", "seeds", "san_rafael.csv")
  process_csv_documents(san_rafael, sr_csv_path)
end
