RailsObservatory::Engine.routes.draw do
  resources :requests, only: [:index, :show]
  resources :jobs, only: :index
  resources :logs, only: :index
  resources :mailers, only: [:index, :show]
  resources :errors, only: [:index, :show]
  root to: "requests#index"
end
