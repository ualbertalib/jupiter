require 'sidekiq/web'
require 'sidekiq/cron/web'
require_dependency 'admin_constraint'

# rubocop is bad and recommends insane things
Rails.application.routes.draw do
  mount Oaisys::Engine, at: '/oai'

  root to: 'welcome#index'

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
      get 'download/:file_set_id', to: 'downloads#download', format: false, as: 'file_download'
      get 'view/:file_set_id/*file_name', to: 'downloads#view', format: false, as: 'file_view'
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

    resources :items, only: [:index, :destroy]

    resources :theses, only: [] do
      collection do
        post :create_draft, controller: 'theses/draft', action: :create
      end

      delete :delete_draft, to: 'theses/draft#destroy'

      resources :draft, only: [:show, :update], controller: 'theses/draft'
      resources :files, only: [:create, :destroy], controller: 'theses/files' do
        member do
          patch :set_thumbnail
        end
      end
    end

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

  # Static pages
  get '/about', to: 'static_pages#about'
  get '/policies', to: 'static_pages#policies'
  get '/contact', to: 'static_pages#contact'

  ## HydraNorth URL redirects
  get '/files/:noid', to: 'redirect#hydra_north_item' # may have query string `?file=filename`
  get '/downloads/:noid', to: 'redirect#hydra_north_item' # may have query string `?file=filename`
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

  get '/rails/blobs/:key', to: redirect('/rails/active_storage/blobs/%{key}/thumbnail.jpg')

  match '/oai/(*all)', to: 'application#service_unavailable', via: [:get, :post]

  # AIP API v1
  namespace :aip, defaults: { format: :n3 } do
    namespace :v1 do
      get '/:model/:id', to: 'aip#show', as: 'model'
      get '/:model/:id/filesets', to: 'aip#file_sets', as: 'model_filesets'
      get '/:model/:id/filesets/:file_set_id', to: 'aip#file_set', as: 'model_file_set'
      get '/:model/:id/filesets/:file_set_id/download', to: 'aip#download_file', as: 'model_fileset_download'
      get '/:model/:id/filesets/:file_set_id/fixity', to: 'aip#fixity_file', as: 'model_fileset_fixity'
      get '/:model/:id/filesets/:file_set_id/original_file', to: 'aip#original_file', as: 'model_fileset_original_file'
    end
  end
end
