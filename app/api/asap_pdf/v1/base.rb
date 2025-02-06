require "grape"
require_relative "sites"

module AsapPdf
  module V1
    class Base < Grape::API
      version "v1", using: :path
      format :json

      mount Sites
    end
  end
end
