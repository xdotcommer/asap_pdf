class Document < ApplicationRecord
  belongs_to :site
  has_many :workflow_histories, class_name: "DocumentWorkflowHistory"

  has_paper_trail versions: {scope: -> { order(created_at: :desc) }}

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

  scope :by_filename, ->(filename) {
    return all if filename.blank?
    where("file_name ILIKE ?", "%#{filename}%")
  }

  scope :by_category, ->(category) {
    return all if category.blank?
    where(document_category: category)
  }

  scope :by_date_range, ->(start_date, end_date) {
    scope = all
    scope = scope.where("modification_date >= ?", start_date) if start_date.present?
    scope = scope.where("modification_date <= ?", end_date) if end_date.present?
    scope
  }

  CONTENT_TYPES = [
    "Unknown", "Agreement", "Agenda", "Brochure", "Diagram", "Flyer", "Form", "Form Instruction",
    "Job Announcement", "Job Description", "Letter", "Map", "Memo", "Policy", "Slides",
    "Press", "Procurement", "Notice", "Report", "Spreadsheet"
  ].freeze

  DECISION_TYPES = ["Unknown", "Leave", "Convert", "Remove", "Remediate"].freeze

  validates :file_name, presence: true
  validates :url, presence: true, format: {with: URI::DEFAULT_PARSER.make_regexp}
  validates :document_status, presence: true, inclusion: {in: %w[discovered downloaded]}
  validates :classification_status, presence: true, inclusion: {in: %w[classification_pending auto_classified classified reclassified]}
  validates :policy_review_status, presence: true, inclusion: {in: %w[policy_pending auto_reviewed reviewed rereviewed]}
  validates :recommendation_status, presence: true, inclusion: {in: %w[recommendation_pending auto_recommendation recommendation_adjusted recommended]}
  validates :document_category, inclusion: {in: CONTENT_TYPES}, allow_nil: true
  validates :accessibility_recommendation, inclusion: {in: DECISION_TYPES}, allow_nil: true

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

  def inference_summary
    if summary.nil?
      endpoint_url = "http://localhost:9000/2015-03-31/functions/function/invocations"
      payload = {
        model_name: "gemini-1.5-pro-latest",
        document_url: url,
        page_limit: 7
      }.to_json
      begin
        response = RestClient.post(endpoint_url, payload, {content_type: :json, accept: :json})
        self.summary = response.body
      rescue RestClient::ExceptionWithResponse => e
        puts "Error: #{e.response.code} #{e.response.body}"
      rescue RestClient::Exception => e
        puts "A RestClient exception occurred: #{e.message}"
      rescue JSON::ParserError => e
        puts "The server returned a malformed JSON response: #{e.message}"
      end
    end
    summary
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
end
