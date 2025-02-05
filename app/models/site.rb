class Site < ApplicationRecord
  belongs_to :user
  has_many :documents

  validates :name, presence: true
  validates :location, presence: true
  validates :primary_url, presence: true
  validates :primary_url, uniqueness: {scope: :user_id}
  validates :name, uniqueness: {scope: [:location, :user_id]}
  validate :ensure_safe_url

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
