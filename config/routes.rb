Rails.application.routes.draw do
  # セッション関連
  get "/login", to: "user_sessions#new", as: :login
  post "/login", to: "user_sessions#create", as: :login_create
  delete "/logout", to: "user_sessions#destroy", as: :logout

  # ユーザー登録関連
  resources :users, only: [ :new, :create, :edit, :update ]

  # ログイン必須のルーティング
  get "/dashboard", to: "static_pages#dashboard", as: :dashboard

  # Googleログイン関連
  post "/auth/:provider", to: lambda { |_env| [ 404, {}, [ "Not Found" ] ] }, as: :auth
  get "/users/auth/:provider/callback", to: "user_sessions#google_oauth2", as: :auth_callback

  # 旅行プラン関連
  resources :travels do
    # スポット関連
    resources :spots, only: [ :new, :create, :index, :show, :edit, :update, :destroy ] do
      collection do
        post :register
        post :save_schedules
        post :create_notification
      end

      member do
        patch :update_order
      end
    end

    # レビュー関連
    resources :travel_reviews, only: [ :create ]

    # 写真共有関連
    resources :photos, only: [ :index, :create, :destroy ] do
      collection do
        get :day
      end
    end
  end

  # 静的ページ関連
  root to: "static_pages#top"
  get "/privacy_policy", to: "static_pages#privacy_policy", as: :privacy_policy
  get "/terms_of_service", to: "static_pages#terms_of_service", as: :terms_of_service

  # お問い合わせ関連
  get "/contact_us", to: "contacts#new", as: :contact_us
  post "/contact_us", to: "contacts#create"

  # パスワードリセット関連
  resources :password_resets, only: [ :new, :create, :edit, :update ]

  # 友達管理関連
  resources :friendships, only: [ :index, :create ] do
    member do
      patch :accept
      patch :reject
    end
  end
  get "/friend_requests", to: "friendships#requests", as: :friend_requests

  # 持物リスト関連
  resources :packing_lists, only: [ :index, :new, :create, :show, :destroy ] do
    resources :packing_items, only: [ :update ] do
      collection do
        post :clear_all
      end
    end
  end

  # 通知関連
  resources :notifications, only: [ :index, :destroy ] do
    member do
      post :mark_as_read
    end
  end
end
