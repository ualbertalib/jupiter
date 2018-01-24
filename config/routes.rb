require 'sidekiq/web'
require_dependency 'admin_constraint'

Rails.application.routes.draw do
  resources :items do
    member do
      match 'download/*file_name' => 'file_sets#download', :format => false, via: :get
      match 'view/*file_name' => 'file_sets#show', :format => false, via: :get
    end
  end

  get 'search', to: 'search#index'
  get 'profile', to: 'profile#index'

  resources :communities, only: [:index, :show] do
    resources :collections, only: [:show]
  end

  namespace :admin, constraints: AdminConstraint.new do
    root to: 'dashboard#index'

    resources :users, only: [:index, :show] do
      member do
        patch :suspend
        patch :unsuspend
        patch :grant_admin
        patch :revoke_admin
        post :login_as_user
      end
    end

    resources :communities do
      resources :collections, except: [:index]
    end

    resources :items, only: [:index]

    resources :announcements, only: [:index, :destroy, :create]
  end

  post '/logout_as_user', to: 'sessions#logout_as_user'
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

  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: :xml }, as: :sitemapindex
  get 'sitemap-communities.xml', to: 'sitemap#communities', defaults: { format: :xml }, as: :communities_sitemap
  get 'sitemap-collections.xml', to: 'sitemap#collections', defaults: { format: :xml }, as: :collections_sitemap
  get 'sitemap-items.xml', to: 'sitemap#items', defaults: { format: :xml }, as: :items_sitemap
  get 'sitemap-theses.xml', to: 'sitemap#theses', defaults: { format: :xml }
  root to: 'welcome#index'
end
