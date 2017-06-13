Rails.application.routes.draw do
  root to: 'welcome#index'
  
  resources :works

  resources :communities do
    resources :collections
  end
end
