Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  resource :session
  get "login", to: "sessions#new", as: :login

  resources :dashboard, only: [:index] do
    collection do
      post :upload_pdf
    end
  end

  resources :sites do
    resources :documents, shallow: true
  end

  mount AsapPdf::API => "/api"
  get "api-docs", to: "api_docs#index"

  root "sites#index"
end
