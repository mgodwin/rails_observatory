RailsObservatory::Engine.routes.draw do
  resources :requests, only: :index

  resources :request_traces, only: [:index, :show] do
    get "recent", on: :collection
  end
  resources :job_traces, only: [:index, :show] do
    get "recent", on: :collection
  end

  resources :metrics, only: :index, param: :name do
    get "autocomplete", on: :collection
    get "labels", on: :member
  end

  resources :jobs, only: [:index, :show]
  resources :mailers, only: [:index, :show] do
    get "recent", on: :collection
  end
  resources :errors, only: [:index, :show]
  resources :storage, only: [:index]
  resources :time_series, only: [:index]
  resources :updates, only: [:index]
  get "usage", to: "usage#index", as: :usage
  root to: "requests#index"
end
