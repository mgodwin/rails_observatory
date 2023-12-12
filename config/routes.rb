RailsObservatory::Engine.routes.draw do

  resources :requests, only: [:index, :show]
  resources :jobs, only: :index
  root to: "requests#index"
end
