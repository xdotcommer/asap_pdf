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

  describe "S3 functionality" do
    describe "#s3_endpoint_prefix" do
      it "converts primary_url host to dasherized format" do
        site = build(:site, primary_url: "https://www.city.org")
        expect(site.s3_endpoint_prefix).to eq("www-city-org")
      end

      it "handles URLs with multiple subdomains" do
        site = build(:site, primary_url: "https://docs.sub.city.gov")
        expect(site.s3_endpoint_prefix).to eq("docs-sub-city-gov")
      end

      it "handles URLs with dashes" do
        site = build(:site, primary_url: "https://my-city.org")
        expect(site.s3_endpoint_prefix).to eq("my-city-org")
      end

      it "returns nil for blank URL" do
        site = build(:site, primary_url: nil)
        expect(site.s3_endpoint_prefix).to be_nil
      end
    end

    describe "#s3_endpoint" do
      it "combines S3_BUCKET with endpoint prefix" do
        site = build(:site, primary_url: "https://www.city.org")
        expect(site.s3_endpoint).to eq("s3://cfa-aistudio-asap-pdf/www-city-org")
      end

      it "returns nil for blank URL" do
        site = build(:site, primary_url: nil)
        expect(site.s3_endpoint).to be_nil
      end
    end

    describe "#s3_key_for" do
      it "combines endpoint prefix with filename" do
        site = build(:site, primary_url: "https://www.city.org")
        expect(site.s3_key_for("test.pdf")).to eq("www-city-org/test.pdf")
      end

      it "handles nested paths in filename" do
        site = build(:site, primary_url: "https://www.city.org")
        expect(site.s3_key_for("folder/test.pdf")).to eq("www-city-org/folder/test.pdf")
      end
    end
  end

  describe "#as_json" do
    let(:site) { create(:site, primary_url: "https://www.city.org") }

    it "excludes user_id, created_at, and updated_at" do
      json = site.as_json
      expect(json.keys).not_to include("user_id", "created_at", "updated_at")
    end

    it "includes s3_endpoint" do
      json = site.as_json
      expect(json["s3_endpoint"]).to eq("s3://cfa-aistudio-asap-pdf/www-city-org")
    end

    it "includes basic attributes" do
      json = site.as_json
      expect(json).to include(
        "id" => site.id,
        "name" => site.name,
        "location" => site.location,
        "primary_url" => site.primary_url
      )
    end
  end
end
