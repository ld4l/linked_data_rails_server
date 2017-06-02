Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get "/download", controller: :dataset, action: :download
  get "/:context/:localname(.:format)", controller: :dataset, action: :standard, :defaults => { :format => 'rdf' }
  get "/:context(.:format)", controller: :dataset, action: :index, :defaults => { :format => 'rdf' }
  get "/(.:format)", controller: :dataset, action: :index, :defaults => { :format => 'rdf' }
end
