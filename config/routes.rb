Rails.application.routes.draw do

  get :status, to: 'application#status'

  root to: 'shops#index'
  resources :shops, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :shipping_methods, only: [:index, :new, :create, :edit, :update, :destroy] do
      patch :toggle, on: :member
      get :duplicate, on: :member
      get :copy_to_all_shops, on: :member
    end
    resources :delivery_types do
      patch :toggle, on: :member
    end
    resources :periods

  end

  match '/quote', to: 'api#quote', via: [:get, :post], format: :json
  match '/delivery_date', to: 'api#delivery_date', via: [:get, :post], format: :json
  match '/delivery_types', to: 'api#delivery_types', via: [:get, :post], format: :json
end
