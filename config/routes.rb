Rails.application.routes.draw do
  # セッション関連
  get '/login', to: 'user_sessions#new', as: :login
  post '/login', to: 'user_sessions#create', as: :login_create
  delete '/logout', to: 'user_sessions#destroy', as: :logout
  
  # ユーザー登録関連
  resources :users, only: %i[new create]
  
  # ログイン必須のルーティング
  get 'dashboard', to: 'static_pages#dashboard'
  
  # 旅行プラン関連
  resources :travels do
    resources :spots do
      collection do
        post :register
        post :save_schedules
      end
      member do
        patch :update_order
      end
    end

    # スポット関連のルーティング
    resources :spots, only: %i[new create] do
      collection do
        post :register
        post :save_schedules
      end
    end
  end
  
  # ルートパス
  root 'static_pages#top'

  resources :friendships, only: [:index, :create] do
    member do
      patch :accept
      patch :reject
    end
  end
  get 'friend_requests', to: 'friendships#requests', as: :friend_requests
end
