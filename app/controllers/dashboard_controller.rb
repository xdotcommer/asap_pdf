class DashboardController < AuthenticatedController
  def index
    @sites = Current.session&.user&.sites
    @documents = Current.session&.user&.documents
    flash.now[:notice] = "Welcome back, #{Current.session&.user&.email_address}!" if flash[:notice].nil?
  end
end
