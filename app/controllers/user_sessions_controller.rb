class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  skip_before_action :check_session_timeout, only: %i[new create destroy]

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
end
