require "active_support/core_ext/integer/time"

Rails.application.configure do
  # アセット関連の設定（変更なし）
  config.assets.debug = true
  config.assets.compile = true
  config.assets.quiet = true
  config.assets.digest = true
  config.assets.precompile += %w( *.js *.css )
  config.assets.check_precompiled_asset = false
  config.public_file_server.enabled = true
  config.sass.inline_source_maps = true
  config.assets.unknown_asset_fallback = false

  # 静的ファイル配信の設定（変更なし）
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # メール設定（追加）
  config.action_mailer.raise_delivery_errors = true  # エラーを表示する
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { 
    host: 'tri-planner.com'
  }

  # SMTP設定（追加）
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:              'gmail.com',
    user_name:           ENV['SMTP_USERNAME'],
    password:            ENV['SMTP_PASSWORD'],
    authentication:       'plain',
    enable_starttls_auto: true
  }

  # 以下の設定は変更なし
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store
  config.active_storage.service = :local
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_record.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true
  config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.raise_on_missing_callback_actions = true
  config.hosts.clear
  config.web_console.whitelisted_ips = '0.0.0.0/0'
end
