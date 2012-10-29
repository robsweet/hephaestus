Hephaestus::Application.routes.draw do
  resource :puppet_modules, :only => [:index, :new, :create]

  match ':user/:module(.:format)',  :as => 'destroy_puppet_module', :to => 'puppet_modules#destroy', :via => :delete

  ##  These two are to work with the existing Forge API
  match ':user/:module(.:format)',   :to => 'puppet_modules#releases',     :via => :get
  match 'api/v1/releases(.:format)', :to => 'puppet_modules#dependencies', :via => :get


end
