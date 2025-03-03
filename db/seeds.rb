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

  # Create Austin site
  austin = Site.find_or_create_by!(
    name: "The Official Website of The City of Austin",
    location: "Austin, TX",
    primary_url: "https://www.austintexas.gov/",
    user: admin
  )
  puts "Created site: #{austin.name}"

  ga = Site.find_or_create_by!(
    name: "georgia.gov",
    location: "Georgia",
    primary_url: "https://georgia.gov/",
    user: admin
  )
  puts "Created site: #{ga.name}"

  # Process Georgia documents
  puts "\nProcessing Georgia documents..."
  ga.process_csv_documents(Rails.root.join("db", "seeds", "georgia.csv"))

  # Process Austin documents
  puts "\nProcessing Austin documents..."
  austin.process_csv_documents(Rails.root.join("db", "seeds", "austin.csv"))

  # Process Austin documents
  puts "\nProcessing Austin documents..."
  austin.process_csv_documents(Rails.root.join("db", "seeds", "austin.csv"))

  # Process Salt Lake City documents
  puts "\nProcessing Salt Lake City documents..."
  slc.process_csv_documents(Rails.root.join("db", "seeds", "salt_lake_city.csv"))

  # Process San Rafael documents
  puts "\nProcessing San Rafael documents..."
  san_rafael.process_csv_documents(Rails.root.join("db", "seeds", "san_rafael.csv"))

  # Process Salt Lake City documents
  puts "\nProcessing Salt Lake City documents..."
  slc.process_csv_documents(Rails.root.join("db", "seeds", "salt_lake_city.csv"))

end
