# Dockerfile
FROM travel-app-base:latest

# ARGを追加
ARG UID=1000
ARG GID=1000

USER root

# Gemfileのコピーと依存関係のインストール
COPY --chown=app:app Gemfile Gemfile.lock ./
RUN bundle config set --local path 'vendor/bundle' && \
    bundle install --jobs 4 --retry 3

# アプリケーションのコピー
COPY --chown=app:app . .

# yarnのセットアップ
RUN yarn install

# JavaScript関連のセットアップ
ENV RAILS_ENV=development
RUN bundle exec rails javascript:install:esbuild

# ユーザーを戻す
USER app
