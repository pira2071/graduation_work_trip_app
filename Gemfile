# RubyGemsをGemのソースとして指定。すべてのGemはこのリポジトリから取得される。
source "https://rubygems.org"

# Rails 7.1.x系を使用
gem "rails", "~> 7.1.0"
# Rails 7で導入された新しいアセットパイプライン
gem "propshaft"
# PostgreSQLデータベースをActive Recordで使用するためのアダプタ
gem "pg", "~> 1.1"
# マルチスレッドに対応したWebサーバー。Rails公式推奨のWebサーバー
gem "puma", ">= 5.0"
# JavaScriptのモジュールをインポートマップを使って管理するためのgem。バンドラーを使わずにJSモジュールを扱える。
gem "importmap-rails"
# HotwireのTurboをRailsで使うためのgem。ページの遷移を高速化しSPAのような体験を提供。
gem "turbo-rails"
# HotwireのStimulusをRailsで使うためのgem。JavaScriptを使った軽量なインタラクティブ機能を提供。
gem "stimulus-rails"
# JSON APIを簡単に構築するためのgem。Ruby構文でJSONを生成。
gem "jbuilder"

# Windows環境やJRubyでタイムゾーン情報を扱うために必要なgem。
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Railsのキャッシュ、ジョブキュー、Action Cableのデータベースバックエンドアダプタ。
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Railsの起動時間を高速化するgem。クラスのロード等を最適化。
gem "bootsnap", require: false

# Dockerコンテナを使ったデプロイツール。本番環境へのデプロイに使用。
gem "kamal", require: false

# PumaにHTTPアセットキャッシング/圧縮とX-Sendfile高速化機能を追加。
gem "thruster", require: false

# Rubyのデバッグツール
gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

# JavaScriptバンドラー（Webpackやesbuildなど）をRailsで使うためのgem。
gem "jsbundling-rails"

# BootstrapフレームワークとSASSコンパイラをRailsで使うためのgem。
gem "bootstrap"
gem "sassc-rails"

# 認証機能を実装するためのgem。
gem "sorcery", "0.16.5"

# 開発環境とテスト環境でのみ使用するgemをグループ化。
group :development, :test do
  # RSpecテストフレームワーク
  gem "rspec-rails"
  # テスト用のオブジェクト生成ライブラリ
  gem "factory_bot_rails"
  # テスト用のダミーデータ生成ライブラリ
  gem "faker"
  # RSpecのマッチャーを拡張するライブラリ
  gem "shoulda-matchers"
  # コントローラーのテストをサポート
  gem "rails-controller-testing"
  # セキュリティ脆弱性の静的解析ツール
  gem "brakeman", require: false
  # Rails公式のコーディングスタイルを強制するツール
  gem "rubocop-rails-omakase", require: false
end

# 開発環境でのみ使用するgemをグループ化。
group :development do
  # エラーページでRubyコンソールを提供するgem
  gem "web-console"
end

# テスト環境でのみ使用するgemをグループ化。
group :test do
  # 統合テスト用のヘッドレスブラウザ
  gem "capybara"
  # ブラウザを使用したE2Eテスト用のドライバー
  gem "selenium-webdriver"
end

# 写真の投稿機能用。ファイルアップロード機能とそれに伴う画像処理を担当するgem。
gem "carrierwave", "~> 3.1"
gem "mini_magick", "~> 5.1"

# 環境変数を.envファイルで管理するためのgem。
gem "dotenv-rails"

# SEO対策。HTMLのメタタグを簡単に管理するためのgem。
gem "meta-tags"

# 検索機能を簡単に実装するためのgem。
gem "ransack"

# セキュリテイ対策用
gem "rack-attack"
gem "sanitize"
gem "recaptcha"

# Googleログイン用
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection", "~> 1.0" # CSRF対策
