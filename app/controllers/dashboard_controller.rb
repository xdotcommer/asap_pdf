class DashboardController < ApplicationController
  def index
    @sites = Current.session&.user&.sites
    @documents = Current.session&.user&.documents
    flash.now[:notice] = "Welcome back, #{Current.session&.user&.email_address}!" if flash[:notice].nil?
  end

  def upload_document
    site = Current.session&.user&.sites&.find(params[:site_id])
    document = site.documents.build(document_params)
    if document.save
      redirect_to dashboard_path, notice: "Document uploaded successfully."
    else
      redirect_to dashboard_path, alert: "Failed to upload document."
    end
  end

  private

  def document_params
    params.require(:document).permit(:file, :file_name, :url, :file_size, :last_modified_date, :status, :document_category, :document_category_confidence, :accessibility_recommendation, :accessibility_action, :action_taken_on, :title, :author, :subject, :keywords, :creation_date, :modification_date, :producer, :pdf_version, :number_of_pages)
  end
end
