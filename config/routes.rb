Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "/download", controller: :dataset, action: :download
  get "/index", controller: :dataset, action: :index
  get "(/:organization)", controller: dataset, action: get
  get "/", controller: :dataset, action: :get
end
