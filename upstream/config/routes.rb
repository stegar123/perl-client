Rails.application.routes.draw do

  apipie
  get '/download', :to => 'pages#download'  
  get '/api_doc', :to => 'pages#api_doc'  
  get '/stats', :to => 'pages#stats'  

  resources :combinations do
    collection do
      get 'interogate'
      get 'unknown'
      get 'unrated'
    end
    member do
      get 'calculate'
    end
  end

  resources :pending_combinations do
    member do
      post 'approve'
      post 'decline'
    end
  end

  # dumb dumb did a typo so we're adding this as another call
  # so this way previous libs are not affected

  namespace :api do
    namespace :v1 do
      resources :combinations do
        collection do 
          get 'interogate'
          get 'interrogate', :to => 'combinations#interogate', :as => 'interrogate'
          post 'submit'
        end
      end
      namespace :test do
        get 'key/:key', :action => 'key'
      end
      get 'download', :to => 'static#download'
      get 'download-p0f-map', :to => 'static#download_p0f_map'
    end
  end

  resources :mac_vendors

  resources :dhcp_vendors

  resources :discoverers do
    collection do
      get 'cache'
    end
  end

  resources :rules do
    resources :conditions
  end

  resources :dhcp_fingerprints do
    collection do
      get 'unknown'
    end
    member do
      post 'trigger_ignore'
    end
  end

  resources :devices do 
    get 'community', on: :new, :to => 'devices#community_new'
    post 'community', on: :new, :to => 'devices#community_create'

    collection do
      get 'search'
      get 'not_approved'
    end
  
    member do 
      get 'approve'
    end
  end

  resources :users do
    member do
      post 'promote/:level', :to => 'users#promote', :as => 'promote'
      post 'demote/:level', :to => 'users#demote', :as => 'demote'
      post 'block'
      post 'unblock'
      post 'request_api'
      get 'generate_key'
    end
    collection do
      get 'register'
      get 'my_account'
      get 'anonymous_users'
    end
    resources :watched_combinations
  end

  get '/events', :to => 'events#index'

  get '/login', :to => 'users#login'
  get '/key_login', :to => 'users#key_login'
  post '/key_login', :to => 'sessions#create'
  get '/auth/:provider/callback', :to => 'sessions#create'
  get '/logout', :to => 'sessions#destroy'

  root 'combinations#index' 

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
