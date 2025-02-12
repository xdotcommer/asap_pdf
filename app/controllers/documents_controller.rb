class DocumentsController < AuthenticatedController
  def index
    @site = Site.find(params[:site_id])
    @documents = @site.documents
    @total_documents = @documents.count
    @document_categories = @site.documents.distinct.pluck(:document_category).compact.sort

    # Apply filters
    if params[:category].present?
      @documents = @documents.where(document_category: params[:category])
    end
    if params[:filename].present?
      @documents = @documents.where("file_name ILIKE ?", "%#{params[:filename]}%")
    end

    # Apply date range filter
    if params[:start_date].present?
      @documents = @documents.where("modification_date >= ?", params[:start_date])
    end
    if params[:end_date].present?
      @documents = @documents.where("modification_date <= ?", params[:end_date])
    end

    # Apply sorting
    if params[:sort].present?
      direction = (params[:direction] == "desc") ? :desc : :asc
      case params[:sort]
      when "file_name"
        @documents = @documents.order(file_name: direction)
      when "source"
        @documents = @documents.order(source: direction)
      when "modification_date"
        @documents = @documents.order(modification_date: direction)
      end
    else
      # Default sort by modification date desc
      @documents = @documents.order(modification_date: :asc)
      params[:direction] = "asc"
      params[:sort] = "modification_date"
    end

    @documents = @documents.page(params[:page]).per(20)
  end
end
