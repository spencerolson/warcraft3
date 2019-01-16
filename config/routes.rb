Rails.application.routes.draw do
  resources :units, except: [:edit, :update, :delete]
  root "units#counters"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
