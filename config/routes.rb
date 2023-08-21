RailsObservatory::Engine.routes.draw do

  resources :controller_metrics, only: [:index, :show]
  root to: "controller_metrics#index"
end
