require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TravelApp
  class Application < Rails::Application
    config.generators do |g|
      g.helper false #helperを生成しない
      g.test_framework false #testファイルを生成しない
      g.skip_routes true #ルーティングを生成しない
    end
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # セキュリティ関連のパスを自動読み込み
    config.autoload_paths += %W(#{config.root}/app/lib)

    # Rack::Attackミドルウェアの追加
    config.middleware.use Rack::Attack

    # セキュリティ関連のヘッダー強化
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'SAMEORIGIN',
      'X-XSS-Protection' => '1; mode=block',
      'X-Content-Type-Options' => 'nosniff',
      'X-Download-Options' => 'noopen',
      'X-Permitted-Cross-Domain-Policies' => 'none',
      'Referrer-Policy' => 'strict-origin-when-cross-origin'
    }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # ブラウザサポートの設定を追加
    config.active_support.browser_compatibility = true
    # アセットパイプラインの設定を追加
    config.assets.enabled = true
    config.assets.version = '1.0'

    # Google Maps APIキーを設定
    config.x.google_maps_api_key = ENV['GOOGLE_MAPS_API_KEY']

    # 環境変数読み込み
    if Rails.env.development? || Rails.env.test? || Rails.env.production?
      Dotenv::Railtie.load
    end

  end
end
