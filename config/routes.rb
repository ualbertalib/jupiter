require 'sidekiq/web'
require_dependency 'admin_constraint'

Rails.application.routes.draw do
  resources :items, only: [:show, :edit] do
    collection do
      post :create_draft, controller: 'items/draft', action: :create
    end

    delete :delete_draft, to: 'items/draft#destroy'

    resources :draft, only: [:show, :update], controller: 'items/draft'
    resources :files, only: [:create, :destroy], controller: 'items/files' do
      member do
        patch :set_thumbnail
      end
    end

    member do
      match 'download/:file_set_id' => 'file_sets#download', :format => false, via: :get
      match 'view/:file_set_id/*file_name' => 'file_sets#show', :format => false, via: :get
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

  # Dynamic robots.txt
  get 'robots.txt' => 'robots#robots'

  root to: 'welcome#index'

  ## HydraNorth URL redirects
  get '/files/:noid', to: 'redirect#hydra_north_item'
  get '/files/:noid/:filename', to: 'redirect#hydra_north_file', constraints: { filename: /[^\/]+/ }
  get '/collections/:noid', to: 'redirect#hydra_north_community_collection'

  ## Pre-HydraNorth URL redirects
  get '/public/view/item/:uuid', to: 'redirect#fedora3_item'
  get '/public/view/item/:uuid/:ds', to: 'redirect#fedora3_datastream'
  get '/public/view/item/:uuid/:ds/:filename', to: 'redirect#fedora3_datastream', constraints: { filename: /[^\/]+/ }
  get '/public/datastream/get/:uuid/:ds', to: 'redirect#fedora3_datastream'
  get '/public/datastream/get/:uuid/:ds/:filename', to: 'redirect#fedora3_datastream',
                                                    constraints: { filename: /[^\/]+/ }
  get '/public/view/collection/:uuid', to: 'redirect#fedora3_collection'
  get '/public/view/community/:uuid', to: 'redirect#fedora3_community'
  get '/public/view/author/:username', to: 'redirect#no_longer_supported'
  get '/action/submit/init/thesis/:uuid', to: 'redirect#no_longer_supported'
  get '/downloads/:id', to: 'redirect#sufiadownload'
end
