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
      redirect_to login_path, danger: t("notices.session.timeout")
    else
      # 最終アクセス時間を更新
      session[:last_access_time] = Time.current
    end
  end

  def convert_flash_type(type)
    case type.to_sym
    when :notice, :success
      "success"
    when :alert, :danger
      "danger"
    when :warning
      "warning"
    when :info
      "info"
    else
      "info"  # デフォルトはinfo
    end
  end

  private

  def not_authenticated
    redirect_to login_path, danger: t("notices.session.authentication_required")
  end

  def session_expired?
    last_access_time = session[:last_access_time]
    return true unless last_access_time

    (Time.current - last_access_time.to_time) > 1.hour
  end
end
