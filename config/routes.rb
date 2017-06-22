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
end
