require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#document_source" do
    it "returns empty text and nil url for nil source" do
      expect(helper.document_source(nil)).to eq({text: "", url: nil})
    end

    it "formats a single source URL for display" do
      url = "https://www.example.com/path/to/document"
      result = helper.document_source(url)
      expect(result[:text]).to eq("path ▸ to ▸ document")
      expect(result[:url]).to eq(url)
    end

    it "handles URLs without paths" do
      url = "https://www.example.com"
      result = helper.document_source(url)
      expect(result[:text]).to eq("https://www.example.com")
      expect(result[:url]).to eq(url)
    end
  end

  describe "#format_metadata" do
    it "returns dash for nil values" do
      expect(helper.format_metadata(nil)).to eq("—")
    end

    it "returns dash for empty strings" do
      expect(helper.format_metadata("")).to eq("—")
    end

    it "returns the value for non-empty strings" do
      expect(helper.format_metadata("test")).to eq("test")
    end
  end

  describe "#short_number" do
    it "formats thousands" do
      expect(helper.short_number(1234)).to eq("1.23k")
    end

    it "formats millions" do
      expect(helper.short_number(1234567)).to eq("1.23M")
    end

    it "formats billions" do
      expect(helper.short_number(1234567890)).to eq("1.23B")
    end
  end

  describe "#safe_url" do
    it "returns nil for invalid URLs" do
      expect(helper.safe_url("not a url")).to be_nil
    end

    it "returns nil for non-HTTP URLs" do
      expect(helper.safe_url("ftp://example.com")).to be_nil
    end

    it "returns the URL for valid HTTP URLs" do
      url = "http://example.com"
      expect(helper.safe_url(url)).to eq(url)
    end

    it "returns the URL for valid HTTPS URLs" do
      url = "https://example.com"
      expect(helper.safe_url(url)).to eq(url)
    end
  end
end
