module AuthenticationHelpers
  def login_user(user = nil)
    user ||= create(:user)
    login_user_params = { email: user.email, password: 'password' }
    post login_create_path, params: login_user_params
    user
  end

  def login_as(user)
    visit login_path
    fill_in 'email', with: user.email
    fill_in 'password', with: 'password'
    click_button 'ログイン'
  end
end
