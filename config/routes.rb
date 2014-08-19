Rails.application.routes.draw do
  get '/status', to: 'application#status'
end
