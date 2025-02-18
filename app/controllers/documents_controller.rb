class DocumentsController < AuthenticatedController
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:update_document_category, :update_accessibility_recommendation, :update_status, :update_notes]
  before_action :set_site, except: [:update_document_category, :update_accessibility_recommendation, :update_notes]
  before_action :set_document_for_update, only: [:update_document_category, :update_accessibility_recommendation, :update_notes]
  before_action :set_document, only: []

  def index
    @documents = @site.documents
      .by_status(params[:status])
      .by_filename(params[:filename])
      .by_category(params[:category])
      .by_date_range(params[:start_date], params[:end_date])
      .order(sort_column => sort_direction)
      .page(params[:page])

    @document_categories = Document::CONTENT_TYPES
    @total_documents = @documents.total_count
  end

  def update_document_category
    if @document.update_column(:document_category, params[:value])
      render json: {
        display_text: params[:value].present? ? params[:value] : "uncategorized"
      }
    else
      render json: {error: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update_accessibility_recommendation
    if @document.update_column(:accessibility_recommendation, params[:value])
      render json: {
        display_text: params[:value].present? ? params[:value] : "undetermined"
      }
    else
      render json: {error: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update_notes
    if @document.update(notes: params[:document][:notes])
      render json: {
        display_text: params[:document][:notes].present? ? params[:document][:notes] : "No notes"
      }
    else
      render json: {error: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def update_status
    @document = Document.joins(:site)
      .where(sites: {user_id: Current.user.id})
      .find(params[:id])

    if @document.update(status: params[:status])
      head :ok
    else
      render json: {error: @document.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private

  def set_site
    @site = Current.user.sites.find(params[:site_id])
  end

  def set_document
    @document = @site.documents.find(params[:id])
  end

  def set_document_for_update
    @document = Document.joins(:site)
      .where(sites: {user_id: Current.user.id})
      .find(params[:id])
  end

  def sort_column
    %w[file_name modification_date].include?(params[:sort]) ? params[:sort] : "file_name"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
