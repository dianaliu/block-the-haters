BlockTheHaters::Application.routes.draw do
  root 'blocks#index'

  resource :blocks do
    post :upload
    post :block_users
    get :export, :defaults => { :format => 'json' }
  end

  get 'auth/:provider/callback', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy', as: 'logout'
end
