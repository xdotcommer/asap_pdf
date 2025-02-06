require "grape"

module AsapPdf
  module V1
    class Sites < Grape::API
      format :json

      resource :sites do
        desc "Return list of sites"
        get do
          Site.all
        end

        desc "Return a specific site"
        params do
          requires :id, type: Integer, desc: "Site ID"
        end
        get ":id" do
          Site.find(params[:id])
        end
      end
    end
  end
end
