class AuthenticatedController < ApplicationController
  include Authentication

  allow_browser versions: :modern
end
