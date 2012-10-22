Hephaestus::Application.routes.draw do

  match ':user/:module(.:format)', :to => 'puppet_module#releases'
  match 'api/v1/releases(.:format)', :to => 'puppet_module#dependencies'

end
