RailsObservatory::Engine.routes.draw do
  resources :requests, only: [:index, :show]

  resources :traces, only: [:index, :show], path: 'traces/:type', as: :traces_by_type do
    get 'recent', on: :collection
  end

  resources :metrics, only: :index do
    get 'autocomplete', on: :collection
  end

  resources :jobs, only: [:index, :show]
  resources :mailers, only: [:index, :show]
  resources :errors, only: [:index, :show]
  resources :time_series, only: [:index]
  resources :updates, only: [:index]
  get 'usage', to: 'usage#index', as: :usage
  root to: "requests#index"
end
