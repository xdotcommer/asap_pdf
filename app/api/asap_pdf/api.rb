require "grape"
require "grape-swagger"

module AsapPdf
  class API < Grape::API::Instance
    format :json

    desc "Return list of sites"
    get "/sites" do
      Site.all
    end

    desc "Return a specific site"
    params do
      requires :id, type: Integer, desc: "Site ID"
    end
    get "/sites/:id" do
      Site.find(params[:id])
    end

    add_swagger_documentation(
      api_version: "v1",
      hide_documentation_path: true,
      mount_path: "/swagger_doc",
      hide_format: true,
      info: {
        title: "ASAP PDF API",
        description: "API for managing ASAP PDF resources"
      }
    )
  end
end
