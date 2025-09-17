Rails.application.routes.draw do
  resources :users do
    # Nested deliveries for a specific user context
    resources :deliveries, only: [ :index, :create ], module: nil, controller: "deliveries" do
      collection do
        # /users/:user_id/deliveries/analytics (scoped) could be added later
      end
    end
  end
  resources :deliveries do
    collection do
      get :analytics
      get "user/:user_id", to: "deliveries#by_user", as: :by_user
    end
  end

  # Friendly dashboard route (alias of deliveries#index)
  get "/dashboard", to: "deliveries#index", as: :dashboard
  root to: "deliveries#index"

  # Authentication routes
  post "/login", to: "sessions#create"
  post "/promote_admin", to: "sessions#promote_admin"

  # Admin routes
  namespace :admin do
    get :all_deliveries
    get :all_users
    post "users/:user_id/promote", to: "admin#promote_user"
    post "users/:user_id/demote", to: "admin#demote_user"
  end

  # API health check for frontend debugging
  get "api/health", to: proc { [ 200, { "Content-Type" => "application/json" }, [ { status: "ok", timestamp: Time.current }.to_json ] ] }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
