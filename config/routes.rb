Rails.application.routes.draw do
  root to: 'welcome#index'

  resources :works do
    collection do
      get 'search'
    end
  end

  resources :communities do
    resources :collections
  end

  get 'login', to: "sessions#new"
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/auth/failure', to: 'sessions#failure', via: [:get, :post]
  match '/logout', to: 'sessions#destroy', via: [:get, :post]
end
