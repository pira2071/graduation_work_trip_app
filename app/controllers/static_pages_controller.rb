class StaticPagesController < ApplicationController
  skip_before_action :require_login, only: %i[top]
  skip_before_action :require_login, except: [:dashboard]  # ダッシュボードなど、ログインが必要なアクションのみrequire_login適用

  def top; end

  def dashboard; end  # ログインユーザー専用のダッシュボード画面
end