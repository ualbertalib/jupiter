require 'sidekiq/web'
require_dependency 'admin_constraint'

Rails.application.routes.draw do
  resources :items do
    collection do
      get 'search'
    end
  end

  resources :file_sets, only: [] do
    member do
      match 'download/*file_name' => 'file_sets#download_original', :format => false, via: :get
      match '*file_name' => 'file_sets#view_original', :format => false, via: :get
    end
  end

  resources :communities do
    resources :collections, except: [:index]
  end

  namespace :admin, constraints: AdminConstraint.new do
    root to: 'dashboard#index'

    resources :users, only: [:index, :show] do
      member do
        patch :suspend
        patch :unsuspend
        patch :grant_admin
        patch :revoke_admin
        post :impersonate
      end
    end

    resources :communities_and_collections, only: [:show, :create, :new, :index]
    resources :site_notifications, only: [:new, :destroy, :create]
  end

  post '/stop_impersonating', to: 'sessions#stop_impersonating'
  get 'login', to: 'sessions#new'
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match '/auth/failure', to: 'sessions#failure', via: [:get, :post]
  match '/logout', to: 'sessions#destroy', via: [:get, :post]

  # Sidekiq panel
  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  else
    mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new
  end

  root to: 'welcome#index'
end
