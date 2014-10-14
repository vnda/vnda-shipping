Rails.application.routes.draw do
  get :status, to: 'application#status'

  root to: 'shops#index'
  resources :shops, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :shipping_methods, only: [:index, :new, :create, :edit, :update, :destroy] do
      patch :toggle, on: :member
      get :duplicate, on: :member
    end
    resources :delivery_types
  end

  match '/quote', to: 'api#quote', via: [:get, :post], format: :json
end
