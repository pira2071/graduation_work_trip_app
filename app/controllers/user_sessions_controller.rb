class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create google_oauth2]
  skip_before_action :check_session_timeout, only: %i[new create destroy google_oauth2]

  def new; end

  def create
    @user = login(params[:email], params[:password])
    if @user
      session[:last_access_time] = Time.current
      redirect_to root_path, success: t("notices.session.created")
    else
      flash.now[:danger] = t("activerecord.errors.models.user.invalid_login")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:last_access_time] = nil
    logout
    redirect_to root_path, status: :see_other, success: t("notices.session.destroyed")
  end

  def google_oauth2
    @auth = request.env["omniauth.auth"]

    if @auth.nil?
      redirect_to login_path, danger: t("activerecord.errors.models.user.google_auth_failed")
      return
    end

    @user = User.from_omniauth(@auth)

    if @user.persisted? || @user.save
      # ログイン処理
      auto_login(@user)
      # セッションタイムアウト用の値を設定
      session[:last_access_time] = Time.current
      redirect_to root_path, success: t("notices.session.google_login")
    else
      redirect_to login_path, danger: t("activerecord.errors.models.user.google_login_failed", errors: @user.errors.full_messages.join(", "))
    end
  rescue => e
    Rails.logger.error "Google認証エラー: #{e.message}"
    redirect_to login_path, danger: t("activerecord.errors.models.user.google_auth_error")
  end
end
