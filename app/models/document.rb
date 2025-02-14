class Document < ApplicationRecord
  belongs_to :site
  has_many :workflow_histories, class_name: "DocumentWorkflowHistory"

  scope :by_status, ->(status) {
    case status
    when "in_review"
      where(status: "in_review")
    when "done"
      where(status: "done")
    when "", nil
      where("status IS NULL OR status = ?", "")
    else
      all
    end
  }

  CONTENT_TYPES = [
    "Agenda/minutes",
    "Brochure or handout",
    "Diagram, graphic, or technical drawing",
    "Event flyer",
    "Form",
    "Form instructions",
    "Job announcement",
    "Job description",
    "Letter and email correspondence",
    "Map",
    "Memo or white paper",
    "Policies, codes, standards",
    "Presentation slides",
    "Press release, newsletter",
    "Procurement announcement and documentation",
    "Public notice",
    "Report, plan, or study",
    "Spreadsheet or table",
    "Staff report, ordinance, resolution, agreement"
  ].freeze

  DECISION_TYPES = [
    "Leave as-is",
    "Convert to web content",
    "Remove from site",
    "Remediate PDF"
  ].freeze

  validates :file_name, presence: true
  validates :url, presence: true, format: {with: URI::DEFAULT_PARSER.make_regexp}
  validates :document_status, presence: true, inclusion: {in: %w[discovered downloaded]}
  validates :classification_status, presence: true, inclusion: {in: %w[classification_pending auto_classified classified reclassified]}
  validates :policy_review_status, presence: true, inclusion: {in: %w[policy_pending auto_reviewed reviewed rereviewed]}
  validates :recommendation_status, presence: true, inclusion: {in: %w[recommendation_pending auto_recommendation recommendation_adjusted recommended]}

  before_validation :set_defaults

  def s3_path
    "#{site.s3_endpoint_prefix}/#{id}/document.pdf"
  end

  def s3_bucket
    @s3_bucket ||= Aws::S3::Resource.new(
      access_key_id: storage_config[:access_key_id],
      secret_access_key: storage_config[:secret_access_key],
      region: storage_config[:region],
      endpoint: storage_config[:endpoint],
      force_path_style: storage_config[:force_path_style]
    ).bucket(storage_config[:bucket])
  end

  def s3_object
    s3_bucket.object(s3_path)
  end

  def file_versions
    s3_bucket.object_versions(prefix: s3_path)
  end

  def latest_file
    file_versions.first
  end

  def file_version(version_id)
    s3_object.get(version_id: version_id)
  end

  def version_metadata(version)
    {
      version_id: version.version_id,
      modification_date: version.modification_date,
      size: version.size,
      etag: version.etag
    }
  end

  state_machine :document_status, initial: :discovered do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    event :download do
      transition discovered: :downloaded
    end
  end

  state_machine :classification_status, initial: :classification_pending do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    before_transition on: :complete_classification do |document, transition|
      args = transition.args.first || {}
      document.recommended_category = args[:category]
      document.category_confidence = args[:confidence]
    end

    before_transition on: :approve_classification do |document|
      document.approved_category = document.recommended_category
    end

    before_transition on: :change_classification do |document, transition|
      args = transition.args.first || {}
      document.changed_category = args[:new_category]
    end

    event :complete_classification do
      transition classification_pending: :auto_classified
    end

    event :approve_classification do
      transition auto_classified: :classified
    end

    event :change_classification do
      transition auto_classified: :reclassified
    end
  end

  state_machine :policy_review_status, initial: :policy_pending do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    before_transition on: :complete_policy_review do |document, transition|
      args = transition.args.first || {}
      document.recommended_accessibility_action = args[:action]
      document.accessibility_confidence = args[:confidence]
    end

    before_transition on: :approve_policy do |document|
      document.approved_accessibility_action = document.recommended_accessibility_action
    end

    before_transition on: :change_policy do |document, transition|
      args = transition.args.first || {}
      document.changed_accessibility_action = args[:new_action]
    end

    event :complete_policy_review do
      transition policy_pending: :auto_reviewed
    end

    event :approve_policy do
      transition auto_reviewed: :reviewed
    end

    event :change_policy do
      transition auto_reviewed: :rereviewed
    end
  end

  state_machine :recommendation_status, initial: :recommendation_pending do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    event :complete_recommendation do
      transition recommendation_pending: :auto_recommendation
    end

    event :change_recommendation do
      transition auto_recommendation: :recommendation_adjusted
    end

    event :approve_recommendation do
      transition %i[auto_recommendation recommendation_adjusted] => :recommended
    end
  end

  private

  def storage_config
    @storage_config ||= begin
      config = Rails.application.config.active_storage.service_configurations[Rails.env.to_s]
      raise "S3 storage configuration not found for #{Rails.env}" unless config
      config.symbolize_keys
    end
  end

  def set_defaults
    self.document_status = "discovered" unless document_status
    self.classification_status = "classification_pending" unless classification_status
    self.policy_review_status = "policy_pending" unless policy_review_status
    self.recommendation_status = "recommendation_pending" unless recommendation_status
  end

  def create_workflow_history(transition)
    metadata = case transition.event
    when :complete_classification
      transition.args.first&.slice(:category, :confidence) || {}
    when :change_classification
      transition.args.first&.slice(:new_category) || {}
    when :complete_policy_review
      transition.args.first&.slice(:action, :confidence) || {}
    when :change_policy
      transition.args.first&.slice(:new_action) || {}
    else
      {}
    end

    history = workflow_histories.create(
      status_type: transition.machine.name.to_s,
      from_status: transition.from,
      to_status: transition.to,
      action_type: transition.event.to_s,
      metadata: metadata,
      user: site.user,
      created_at: Time.current
    )
    raise "Failed to create workflow history: #{history.errors.full_messages.join(", ")}" unless history.persisted?
  end
end
