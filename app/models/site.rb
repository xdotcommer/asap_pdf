class Site < ApplicationRecord
  belongs_to :user
  has_many :documents, dependent: :destroy

  validates :name, presence: true
  validates :location, presence: true
  validates :primary_url, presence: true
  validates :primary_url, uniqueness: {scope: :user_id}
  validates :name, uniqueness: {scope: [:location, :user_id]}
  validate :ensure_safe_url

  def s3_endpoint_prefix
    return nil if primary_url.blank?

    uri = URI.parse(primary_url.strip)
    host = uri.host.downcase
    host.gsub(/[^a-z0-9]/, "-").squeeze("-").gsub(/^-|-$/, "")
  end

  def s3_endpoint
    return nil if s3_endpoint_prefix.nil?
    File.join(S3_BUCKET, s3_endpoint_prefix)
  end

  def s3_key_for(filename)
    File.join(s3_endpoint_prefix, filename)
  end

  def as_json(options = {})
    super.except("user_id", "created_at", "updated_at")
      .merge("s3_endpoint" => s3_endpoint)
  end

  def discover_documents!(document_data)
    document_data.map do |data|
      url = data[:url]
      modification_date = data[:modification_date]

      existing_document = documents.find_by(url: url)

      if existing_document
        if existing_document.modification_date.to_i != modification_date.to_i
          # Document has changed, reset statuses
          existing_document.update! attributes_from(data).reverse_merge(
            file_name: clean_string(data[:file_name]) || existing_document.file_name
          )
        end
        existing_document
      else
        documents.create! attributes_from(data).reverse_merge(
          file_name: clean_string(data[:file_name]) || File.basename(URI.parse(url).path)
        )
      end
    end
  end

  private

  def attributes_from(data)
    {
      url: data[:url],
      modification_date: data[:modification_date],
      file_size: data[:file_size],
      author: clean_string(data[:author]),
      subject: clean_string(data[:subject]),
      keywords: clean_string(data[:keywords]),
      creation_date: data[:creation_date],
      producer: clean_string(data[:producer]),
      pdf_version: clean_string(data[:pdf_version]),
      source: data[:source],
      number_of_pages: data[:number_of_pages],
      document_status: "discovered"
    }
  end

  def clean_string(str)
    return nil if str.nil?
    str.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip
  end

  def ensure_safe_url
    return if primary_url.blank?

    uri = URI.parse(primary_url.strip)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:primary_url, "must be a valid http or https URL")
    end
  rescue URI::InvalidURIError
    errors.add(:primary_url, "is not a valid URL")
  end
end
