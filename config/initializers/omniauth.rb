# グローバル設定を先に行う(Googleログイン)
OmniAuth.config.allowed_request_methods = [:post]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, 
           ENV['GOOGLE_CLIENT_ID'], 
           ENV['GOOGLE_CLIENT_SECRET'], 
           {
             scope: 'email,profile',
             prompt: 'select_account',
             image_aspect_ratio: 'square',
             image_size: 50,
             callback_path: '/users/auth/google_oauth2/callback'
           }
end
