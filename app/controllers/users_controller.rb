class UsersController < ApplicationController
  before_action :require_login, except: %i[new create]
  skip_before_action :check_session_timeout, only: %i[new create]
  before_action :set_user, only: %i[edit update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      auto_login(@user) # ユーザー登録と同時にログイン
      session[:last_access_time] = Time.current # 初回セッション時間を設定
      redirect_to root_path, success: t("notices.user.created")
    else
      flash.now[:danger] = t("activerecord.errors.models.user.registration_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_update_params)
      redirect_to root_path, success: t("notices.user.updated")
    else
      flash.now[:danger] = t("activerecord.errors.models.user.update_failed")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_update_params
    params.require(:user).permit(:name, :email)
  end
end
