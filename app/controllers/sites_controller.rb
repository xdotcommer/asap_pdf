class SitesController < ApplicationController
  before_action :find_site, only: [:show, :edit, :update, :destroy]
  before_action :ensure_user_owns_site, only: [:show, :edit, :update, :destroy]

  def index
    @sites = Current.user.sites.order(created_at: :desc)
  end

  def show
    @documents = @site.documents.order(created_at: :desc)
  end

  def new
    @site = Current.user.sites.build
  end

  def create
    @site = Current.user.sites.build(site_params)

    if @site.save
      redirect_to @site, notice: "Site was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: "Site was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: "Site was successfully deleted.", status: :see_other
  end

  private

  def site_params
    params.require(:site).permit(:name, :location, :primary_url)
  end

  def find_site
    @site = Site.find(params[:id])
  end

  def ensure_user_owns_site
    unless @site.user_id == Current.user.id
      redirect_to sites_path, alert: "You don't have permission to access that site."
    end
  end
end
