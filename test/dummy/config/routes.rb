Rails.application.routes.draw do
  mount RailsObservatory::Engine => "/observatory"

  resources :posts

  # Scenarios for seeding test data
  resources :scenarios, only: [] do
    collection do
      get :success
      get :success_json
      post :create_resource
      patch :update_resource
      delete :delete_resource
      get :not_found
      post :validation_error
      get :server_error
      get :slow_request
      post :unpermitted_params
      get :rate_limited
    end
  end
end
