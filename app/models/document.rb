class Document < ApplicationRecord
  belongs_to :site
  has_many :workflow_histories, class_name: "DocumentWorkflowHistory"

  validates :file_name, presence: true
  validates :url, presence: true, format: {with: URI::DEFAULT_PARSER.make_regexp}
  validates :document_status, presence: true, inclusion: {in: %w[discovered downloaded]}
  validates :classification_status, presence: true, inclusion: {in: %w[pending auto_classified classified reclassified]}
  validates :policy_review_status, presence: true, inclusion: {in: %w[pending auto_reviewed reviewed rereviewed]}
  validates :recommendation_status, presence: true, inclusion: {in: %w[pending auto_recommendation recommendation_adjusted recommended]}

  state_machine :document_status, initial: :discovered do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    event :download do
      transition discovered: :downloaded
    end
  end

  state_machine :classification_status, initial: :pending do
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
      transition pending: :auto_classified
    end

    event :approve_classification do
      transition auto_classified: :classified
    end

    event :change_classification do
      transition auto_classified: :reclassified
    end
  end

  state_machine :policy_review_status, initial: :pending do
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
      transition pending: :auto_reviewed
    end

    event :approve_policy do
      transition auto_reviewed: :reviewed
    end

    event :change_policy do
      transition auto_reviewed: :rereviewed
    end
  end

  state_machine :recommendation_status, initial: :pending do
    after_transition any => any do |document, transition|
      document.send(:create_workflow_history, transition)
    end

    event :complete_recommendation do
      transition pending: :auto_recommendation
    end

    event :change_recommendation do
      transition auto_recommendation: :recommendation_adjusted
    end

    event :approve_recommendation do
      transition %i[auto_recommendation recommendation_adjusted] => :recommended
    end
  end

  private

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
