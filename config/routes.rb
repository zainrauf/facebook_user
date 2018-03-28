Rails.application.routes.draw do
  # require 'devise_token_auth'
  devise_for :users

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      mount_devise_token_auth_for 'User', at: 'auth', :controllers => {:facebook_login => 'api/v1/facebook_login'}
      resources :users
      resources :facebook_login
    end
  end
      # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
