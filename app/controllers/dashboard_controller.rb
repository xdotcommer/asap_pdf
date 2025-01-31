class DashboardController < ApplicationController
  def index
    flash.now[:notice] = "Welcome back, #{Current.session&.user&.email_address}!" if flash[:notice].nil?
  end
end
