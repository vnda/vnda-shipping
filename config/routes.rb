Rails.application.routes.draw do

  get :status, to: 'application#status'

  root to: 'shops#index'
  resources :shops, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :shipping_friendly_errors, only: [:index, :new, :create, :edit, :update, :destroy] do
      get :affected, on: :member
    end
    resources :shipping_methods, only: [:index, :new, :create, :edit, :update, :destroy] do
      patch :toggle, on: :member
      get :duplicate, on: :member
      get :copy_to_all_shops, on: :member
      get :import, on: :collection
      post :import_line, on: :collection
      resources :zip_rules
      resources :map_rules do
        get :download_kml, on: :collection
      end
      resources :places
    end
    resources :shipping_errors, only: [:index]
    resources :delivery_types do
      patch :toggle, on: :member
    end
    resources :periods
    resources :quote_histories, only: [:index, :show]
  end

  match '/quote', to: 'api#quote', via: [:get, :post], format: :json
  match '/local', to: 'api#local', via: :get, format: :json
  match '/delivery_date', to: 'api#delivery_date', via: [:get, :post], format: :json
  match '/delivery_periods', to: 'api#delivery_periods', via: :get, format: :json
  match '/delivery_types', to: 'api#delivery_types', via: [:get, :post], format: :json
  get '/quotation_details/:cart_id', to: 'api#quotation_details'

  post '/intelipost/:shop_token/create', to: 'api#create_intelipost'
  post '/intelipost/:shop_token/shipped', to: 'api#shipped'
end
