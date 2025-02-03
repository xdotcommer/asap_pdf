require "rails_helper"

RSpec.describe Site, type: :model do
  let(:user) { create(:user) }
  subject { build(:site, user: user) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:documents) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:location) }
  it { is_expected.to validate_presence_of(:primary_url) }
  it { is_expected.to allow_value("http://example.com").for(:primary_url) }
  it { is_expected.not_to allow_value("invalid_url").for(:primary_url) }

  it { is_expected.to validate_uniqueness_of(:primary_url).scoped_to(:user_id) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to([:location, :user_id]) }

  describe "uniqueness validations" do
    let(:user) { create(:user) }

    it "validates uniqueness of primary_url scoped to user_id" do
      create(:site, primary_url: "http://example.com", user: user)
      site = build(:site, primary_url: "http://example.com", user: user)
      expect(site).not_to be_valid
    end

    it "validates uniqueness of name scoped to location and user_id" do
      create(:site, name: "Example Site", location: "Example Location", user: user)
      site = build(:site, name: "Example Site", location: "Example Location", user: user)
      expect(site).not_to be_valid
    end
  end
end
