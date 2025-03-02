class ContactsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
  
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.valid?
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
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end
end
