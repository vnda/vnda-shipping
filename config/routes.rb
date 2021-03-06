Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  get :status, to: 'application#status'

  root to: 'shops#index'

  get "/shops/:token/sellers", to: "api#sellers", constraints: { token: /.{32}/ }, defaults: { format: :json }
  patch "/shops/:token/sellers", to: "api#update_seller", constraints: { token: /.{32}/ }, defaults: { format: :json }

  resources :shops do
    patch :set_shipping_order, on: :member
    resources :shipping_friendly_errors, only: [:index, :new, :create, :edit, :update, :destroy] do
      get :affected, on: :member
    end
    resources :shipping_methods, only: [:index, :new, :create, :edit, :update, :destroy] do
      patch :toggle, on: :member
      get :duplicate, on: :member
      get :copy_to_all_shops, on: :member
      get :import, on: :collection
      get :import2, on: :collection
      post :import_line, on: :collection
      post :execute, on: :collection
      post :norder, on: :collection
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
    get :sellers
  end

  match '/quote', to: 'api#quote', via: [:get, :post], defaults: { format: :json }
  get '/local', to: 'api#local', defaults: { format: :json }
  get '/places', to: 'api#places', defaults: { format: :json }
  patch '/update_place_name', to: 'api#update_place_name', defaults: { format: :json }
  get '/shipping_methods', to: 'api#shipping_methods'

  match '/delivery_date', to: 'api#delivery_date', via: [:get, :post], defaults: { format: :json }
  get '/delivery_periods', to: 'api#delivery_periods', defaults: { format: :json }
  match '/delivery_types', to: 'api#delivery_types', via: [:get, :post], defaults: { format: :json }
  get '/quotation_details/:cart_id', to: 'api#quotation_details'
  get '/quotations/:delivery_type_slug/:package_code', to: 'api#quotation', defaults: { format: :json }
  get '/quotations/:delivery_type_slug', to: 'api#quotation', defaults: { format: :json, package_code: nil }

  post '/intelipost/:shop_token/create', to: 'api#create_intelipost'
  post '/intelipost/:shop_token/shipped', to: 'api#shipped'
end
