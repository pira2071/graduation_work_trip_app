class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  skip_before_action :check_session_timeout, only: %i[new create]
 
  def new
    @user = User.new
  end
 
  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user) # ユーザー登録と同時にログイン
      session[:last_access_time] = Time.current # 初回セッション時間を設定
      redirect_to root_path, success: 'ユーザー登録が完了しました'
    else
      flash.now[:danger] = 'ユーザー登録に失敗しました'
      render :new, status: :unprocessable_entity
    end
  end
 
  private
 
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
 end
