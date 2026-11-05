Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Active Storage leaves direct uploads unauthenticated; all uploads go through /admin.
  post "rails/active_storage/direct_uploads", to: ->(_env) { [ 404, {}, [] ] }

  # Error pages, through config.exceptions_app
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#server_error", via: :all

  root "pages#home"
  resources :news, only: %i[index show]

  namespace :admin do
    root to: redirect("/admin/news")
    resource :session, only: %i[new create destroy]
    resources :reports, only: %i[index create update destroy]
    resources :news, except: :show do
      collection { post :preview }
      resources :images, only: %i[create update destroy]
    end
  end

  namespace :api do
    resources :news, only: %i[index show]
    resources :reports, only: :index
  end
end
