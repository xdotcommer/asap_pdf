class DocumentsController < AuthenticatedController
  def index
    @site = Site.find(params[:site_id])
    @documents = @site.documents.page(params[:page]).per(20)
  end
end
