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

    # レビュー用のルーティング
    resources :travel_reviews, only: [:create]

    # 写真共有用のルーティング
    resources :photos, only: [:index, :create, :destroy] do
      collection do
        get :day
      end
    end
  end
  
  # ルートパス
  root 'static_pages#top'

  # 利用規約とプライバシーポリシー用のルート
  get 'privacy_policy', to: 'static_pages#privacy_policy'
  get 'terms_of_service', to: 'static_pages#terms_of_service'

  # お問い合わせフォーム用のルート
  get 'contact_us', to: 'contacts#new'
  post 'contact_us', to: 'contacts#create'

  # 友達管理関連
  resources :friendships, only: [:index, :create] do
    member do
      patch :accept
      patch :reject
    end
  end
  get 'friend_requests', to: 'friendships#requests', as: :friend_requests

  # 持物リスト関連
  resources :packing_lists, only: [:index, :new, :create, :show, :destroy] do
    resources :packing_items, only: [:update] do
      collection do
        post :clear_all
      end
    end
  end
end
