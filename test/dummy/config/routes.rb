Rails.application.routes.draw do
  mount RailsObservatory::Engine => "/observatory"

  resources :posts
end
