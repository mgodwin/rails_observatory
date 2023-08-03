Rails.application.routes.draw do
  mount Observatory::Engine => "/observatory"
end
