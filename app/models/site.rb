class Site < ApplicationRecord
  belongs_to :user
  has_many :documents

  validates :name, presence: true
  validates :location, presence: true
  validates :primary_url, presence: true, format: {with: URI::DEFAULT_PARSER.make_regexp}

  validates :primary_url, uniqueness: {scope: :user_id}
  validates :name, uniqueness: {scope: [:location, :user_id]}
end
