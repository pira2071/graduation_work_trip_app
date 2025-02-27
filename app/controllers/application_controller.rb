class ApplicationController < ActionController::Base
  add_flash_types :success, :info, :warning, :danger
  before_action :require_login
  before_action :check_session_timeout, if: :logged_in?

  def check_session_timeout
    return unless logged_in?
    
    if session[:last_access_time].nil?
      # セッションタイムが存在しない場合は設定する
      session[:last_access_time] = Time.current
      return
    end
    
    last_access_time = Time.zone.parse(session[:last_access_time].to_s)
    if last_access_time < 30.minutes.ago
      logout
      redirect_to login_path, danger: "セッションの有効期限が切れました。再度ログインしてください。"
    else
      # 最終アクセス時間を更新
      session[:last_access_time] = Time.current
    end
  end
  
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
