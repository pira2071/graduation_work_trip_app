Recaptcha.configure do |config|
  config.site_key  = ENV["RECAPTCHA_SITE_KEY"]
  config.secret_key = ENV["RECAPTCHA_SECRET_KEY"]

  # 開発環境ではreCAPTCHAチェックをスキップ（オプション）
  # config.skip_verify_env.push('development') if Rails.env.development?
end
