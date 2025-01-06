Rails.application.config.session_store :cookie_store, 
  key: '_tri_planner_session',
  expire_after: 1.hour # セッションの有効期限を1時間に設定
  