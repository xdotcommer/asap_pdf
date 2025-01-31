# Create a test user for development
if Rails.env.development?
  User.find_or_create_by!(email_address: "admin@codeforamerica.org") do |user|
    user.password = "password"
    puts "Created test user: admin@codeforamerica.org / password"
  end
end
