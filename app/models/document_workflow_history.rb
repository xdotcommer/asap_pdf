class DocumentWorkflowHistory < ApplicationRecord
  belongs_to :document
  belongs_to :user, optional: true

  validates :from_status, presence: true
  validates :to_status, presence: true
  validates :action_type, presence: true
  validates :status_type, presence: true

  # Since we're using jsonb column, Rails will automatically handle the serialization
  # We just need to ensure metadata is always a hash
  def metadata
    super || {}
  end
end
