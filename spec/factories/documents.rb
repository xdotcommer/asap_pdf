FactoryBot.define do
  factory :document do
    file_name { "example.pdf" }
    url { "http://example.com/example.pdf" }
    document_status { "discovered" }
    classification_status { "pending" }
    policy_review_status { "pending" }
    recommendation_status { "pending" }
    site

    trait :downloaded do
      document_status { "downloaded" }
    end

    trait :auto_classified do
      classification_status { "auto_classified" }
      recommended_category { "permit" }
      category_confidence { 0.95 }
    end

    trait :classified do
      classification_status { "classified" }
      recommended_category { "permit" }
      approved_category { "permit" }
    end

    trait :auto_reviewed do
      policy_review_status { "auto_reviewed" }
      recommended_accessibility_action { "ocr_needed" }
      accessibility_confidence { 0.88 }
    end

    trait :reviewed do
      policy_review_status { "reviewed" }
      recommended_accessibility_action { "ocr_needed" }
      approved_accessibility_action { "ocr_needed" }
    end

    trait :auto_recommendation do
      recommendation_status { "auto_recommendation" }
    end

    trait :recommendation_adjusted do
      recommendation_status { "recommendation_adjusted" }
    end

    trait :recommended do
      recommendation_status { "recommended" }
    end
  end
end
