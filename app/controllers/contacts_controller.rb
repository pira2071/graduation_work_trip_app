class ContactsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  before_action :check_for_malicious_input, only: [:create]
  
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    
    # reCAPTCHAの検証を追加
    if verify_recaptcha(model: @contact) && @contact.valid?
      begin
        Rails.logger.info "メール送信開始: #{contact_params.inspect}"
        ContactMailer.contact_email(@contact).deliver_now
        Rails.logger.info "メール送信成功"
        flash[:success] = 'お問い合わせを受け付けました。'
        redirect_to root_path
      rescue => e
        Rails.logger.error "メール送信エラー: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        flash.now[:error] = 'メール送信に失敗しました。'
        render :new, status: :unprocessable_entity
      end
    else
      # reCAPTCHAエラーメッセージを追加（オプション）
      flash.now[:error] = 'reCAPTCHAの確認に失敗しました。' unless verify_recaptcha(model: @contact)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    # Strong Parametersを使用して許可するパラメータを制限
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
  
  # 悪意のある入力をチェックするメソッド（変更なし）
  def check_for_malicious_input
    return unless params[:contact].present?
    
    # パラメータをチェック
    params[:contact].each do |key, value|
      next unless value.is_a?(String)
      
      if SecurityPatterns.contains_dangerous_pattern?(value)
        @contact = Contact.new(contact_params)
        @contact.errors.add(:base, "不正な入力が検出されました")
        Rails.logger.warn "悪意のある入力を検出: #{value} (IP: #{request.remote_ip})"
        render :new, status: :unprocessable_entity
        return
      end
    end
  end
end
