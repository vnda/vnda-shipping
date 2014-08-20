Rails.application.routes.draw do
  get '/status', to: 'application#status'

  root to: 'shops#index'
  resources :shops, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :shipping_methods, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  post '/quote', to: 'api#quote', format: :json
end
