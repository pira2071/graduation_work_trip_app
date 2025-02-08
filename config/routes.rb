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
    
    # スケジュール関連のルーティング
    resources :schedules, only: %i[index update] do
      collection do
        post :reorder  # 順序の並び替え用
        delete :delete_spot
      end
    end

    # スポット関連のルーティング
    resources :spots, only: %i[new create] do
      collection do
        post :register       # Google Mapsからのスポット登録用
        post :update_schedule  # スポットのスケジュール情報更新用
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
