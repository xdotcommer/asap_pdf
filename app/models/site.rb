class Site < ApplicationRecord
  belongs_to :user
  has_many :documents

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

  private

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
