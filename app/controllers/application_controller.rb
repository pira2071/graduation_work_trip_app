class ApplicationController < ActionController::Base
  add_flash_types :success, :info, :warning, :danger
  before_action :require_login
  before_action :check_session_timeout, if: :logged_in?

  private

  def not_authenticated
    redirect_to login_path
  end

  def check_session_timeout
    if session_expired?
      logout
      redirect_to login_path, notice: 'セッションの有効期限が切れました。再度ログインしてください。'
    else
      session[:last_access_time] = Time.current
    end
  end

  def session_expired?
    last_access_time = session[:last_access_time]
    return true unless last_access_time
    
    (Time.current - last_access_time.to_time) > 1.hour
  end
end
