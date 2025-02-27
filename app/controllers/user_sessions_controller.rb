class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create google_oauth2]
  skip_before_action :check_session_timeout, only: %i[new create destroy google_oauth2]

  def new; end

  def create
    @user = login(params[:email], params[:password])
    if @user
      session[:last_access_time] = Time.current
      redirect_to root_path, success: 'ログインしました'
    else
      flash.now[:danger] = 'ログインに失敗しました'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:last_access_time] = nil
    logout
    redirect_to root_path, status: :see_other, success: 'ログアウトしました'
  end

  def google_oauth2
    @auth = request.env['omniauth.auth']
    
    if @auth.nil?
      redirect_to login_path, danger: "認証情報が取得できませんでした"
      return
    end
    
    @user = User.from_omniauth(@auth)
    
    if @user.persisted? || @user.save
      # ログイン処理
      auto_login(@user)
      # セッションタイムアウト用の値を設定
      session[:last_access_time] = Time.current
      redirect_to root_path, success: "Googleアカウントでログインしました"
    else
      redirect_to login_path, danger: "ログインに失敗しました: #{@user.errors.full_messages.join(', ')}"
    end
  rescue => e
    Rails.logger.error "Google認証エラー: #{e.message}"
    redirect_to login_path, danger: "認証処理中にエラーが発生しました"
  end
end
