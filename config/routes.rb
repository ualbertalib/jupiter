require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  constraints(subdomain: 'era') do
    mount Oaisys::Engine, at: '/oai'

    root to: 'welcome#index'

    concern :downloadable do
      member do
        get 'download/:file_set_id', to: DownloadsController.action(:download), format: false, as: 'file_download'
        get 'view/:file_set_id/*file_name', to: DownloadsController.action(:view), format: false, as: 'file_view'
      end
    end

    resources :items, only: [:show, :edit], concerns: :downloadable do
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

      resources :items, only: [:index, :destroy] do
        member do
          patch :reset_doi
        end
      end

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

      resources :google_sessions, only: [:new]

      resources :batch_ingests, only: [:index, :show, :create, :new]
    end

    post '/logout_as_user', to: 'sessions#logout_as_user'
    match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post], as: :login
    match '/auth/failure', to: 'sessions#failure', via: [:get, :post]
    match '/logout', to: 'sessions#destroy', via: [:get, :post]
    post '/auth/system', to: 'sessions#system_login'

    # Sidekiq & Flipper UI
    if Rails.env.development?
      mount Sidekiq::Web => '/sidekiq'
      mount Flipper::UI.app(Flipper) => '/flipper', as: 'flipper'
    else
      constraints AdminConstraint.new do
        mount Sidekiq::Web => '/sidekiq'
        mount Flipper::UI.app(Flipper) => '/flipper', as: 'flipper'
      end
    end

    get 'sitemap.xml', to: 'sitemap#index', defaults: { format: :xml }, as: :sitemapindex
    get 'sitemap-communities.xml', to: 'sitemap#communities', defaults: { format: :xml }, as: :communities_sitemap
    get 'sitemap-collections.xml', to: 'sitemap#collections', defaults: { format: :xml }, as: :collections_sitemap
    get 'sitemap-items.xml', to: 'sitemap#items', defaults: { format: :xml }, as: :items_sitemap
    get 'sitemap-theses.xml', to: 'sitemap#theses', defaults: { format: :xml }, as: :theses_sitemap

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

    # AIP API v1

    namespace :aip,
              defaults: { format: :n3 } do
      namespace :v1 do
        get '/collections/:id',
            to: 'collections#show',
            as: 'collection'
        get '/communities/:id',
            to: 'communities#show',
            as: 'community'
        get '/:entity/:id',
            to: 'entities#show',
            as: 'entity',
            constraints: EntityConstraint.new
        get '/:entity/:id/filesets',
            to: 'entities#file_sets',
            as: 'entity_filesets',
            constraints: EntityConstraint.new
        get '/:entity/:id/file_paths',
            to: 'entities#file_paths',
            as: 'entity_file_paths',
            constraints: EntityConstraint.new
        get '/:entity/:id/filesets/:file_set_id',
            to: 'entities#file_set',
            as: 'entity_file_set',
            constraints: EntityConstraint.new
        get '/:entity/:id/filesets/:file_set_id/fixity',
            to: 'entities#fixity_file',
            as: 'entity_fileset_fixity',
            constraints: EntityConstraint.new
      end
    end
  end

  constraints(subdomain: 'digitalcollections') do
    ## Peel URL redirects
    get '/bibliography/:peel_id(/*page)', to: 'digitization/redirect#peel_book'
    get '/bibliography/:peel_id.:part_number(/*page)', to: 'digitization/redirect#peel_book'
    get '/bibliography/:peel_id.:run.:part_number(/*page)', to: 'digitization/redirect#peel_book'

    get '/newspapers/:publication_code/:year/:month/:day(/*page)', to: 'digitization/redirect#peel_newspaper'

    get '/magee/:peel_image_id', to: 'digitization/redirect#peel_image'
    get '/postcards/:peel_image_id', to: 'digitization/redirect#peel_image'

    # this pattern is shared with jupiter maps so must be before the other inorder to correctly redirect
    get '/maps/:peel_map_id', to: 'digitization/redirect#peel_map', peel_map_id: /M[0-9]{6}/

    scope module: 'digitization', as: 'digitization', only: [:index, :show] do
      resources :books, :newspapers, :images, :maps, concerns: :downloadable
    end
  end

  get 'healthcheck', to: 'healthcheck#index'
end
