FactoryBot.define do
  factory :site do
    name { "Example Site" }
    location { "Example Location" }
    primary_url { "http://example.com" }
    user
  end
end
