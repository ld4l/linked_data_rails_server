Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "/download", controller: :dataset, action: :download
  get "/:context/:localname(.:format)", controller: :dataset, action: :standard
  get "/:context(.:format)", controller: :dataset, action: :index
  get "/(.:format)", controller: :dataset, action: :index
end
