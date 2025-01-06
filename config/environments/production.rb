# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
 # 基本設定
 config.enable_reloading = false
 config.eager_load = true
 config.consider_all_requests_local = false

 # キャッシュ設定
 config.action_controller.perform_caching = true
 config.cache_store = :memory_store
 config.public_file_server.enabled = true
 config.public_file_server.headers = { 
   "Cache-Control" => "public, max-age=#{1.year.to_i}"
 }

 # アセット設定
 config.assets.compile = false
 config.assets.digest = true
 config.serve_static_files = true
 
 # ストレージ設定
 config.active_storage.service = :local

 # SSL設定
 config.force_ssl = true
 config.assume_ssl = true

 # ログ設定
 config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
 config.log_tags = [ :request_id ]
 config.logger = ActiveSupport::TaggedLogging.new(Logger.new('log/production.log'))
 config.active_support.report_deprecations = false

 # メール設定
 config.action_mailer.raise_delivery_errors = true
 config.action_mailer.delivery_method = :smtp
 config.action_mailer.default_url_options = { 
   host: 'tri-planner.com',  # あなたのドメイン名
   protocol: 'https'
 }

 # 国際化設定
 config.i18n.fallbacks = true

 # データベース設定
 config.active_record.dump_schema_after_migration = false
 config.active_record.attributes_for_inspect = [ :id ]

 # ホスト認証設定
 config.hosts << "tri-planner.com"  # あなたのドメイン名
 config.hosts << "www.tri-planner.com"  # www付きドメイン
 config.hosts << IPAddr.new("0.0.0.0/0")  # すべてのIPアドレスを許可

 # セキュリティ設定
 config.action_dispatch.default_headers = {
   'X-Frame-Options' => 'SAMEORIGIN',
   'X-XSS-Protection' => '1; mode=block',
   'X-Content-Type-Options' => 'nosniff'
 }

 # パフォーマンス設定
 config.middleware.use Rack::Deflater  # Gzip圧縮を有効化
end
