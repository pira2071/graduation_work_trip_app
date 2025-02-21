class UserMailer < ApplicationMailer
  default from: ENV['SMTP_USERNAME']

  def reset_password_email(user)
    @user = user
    @url = edit_password_reset_url(
      user.reset_password_token,
      host: 'tri-planner.com'
    )
    
    mail(
      to: user.email,
      subject: '【TriPlanner】パスワードリセットの手順'
    )
  end
end
