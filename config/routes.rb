Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "/download", controller: :dataset, action: :download
  # get "/(:context/:localname)", controller: :dataset, action: :standard, :defaults => { :format => 'rdf' }
  get "/(:context)", controller: :dataset, action: :index, :defaults => { :format => 'rdf' }
  # get "/", controller: :dataset, action: :index, :defaults => { :format => 'rdf' }
end
