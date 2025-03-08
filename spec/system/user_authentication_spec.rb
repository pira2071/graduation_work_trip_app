require 'rails_helper'

RSpec.describe "UserAuthentication", type: :system do
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  
  describe "User Registration" do
    it "allows a visitor to sign up" do
      visit new_user_path
      
      fill_in "お名前", with: "Test User"
      fill_in "メールアドレス", with: "test-new@example.com"
      fill_in "パスワード", with: "password"
      fill_in "パスワード（確認）", with: "password"
      
      click_button "登録"
      
      expect(page).to have_content("アカウントを作成しました")
      expect(page).to have_current_path(root_path)
    end
    
    it "displays validation errors with invalid input" do
      visit new_user_path
      
      fill_in "お名前", with: ""
      fill_in "メールアドレス", with: "invalid-email"
      fill_in "パスワード", with: "pass"
      fill_in "パスワード（確認）", with: "wrong"
      
      click_button "登録"
      
      expect(page).to have_content("ユーザー登録に失敗しました")
      expect(page).to have_content("名前を入力してください")
      expect(page).to have_content("メールアドレスは正しい形式で入力してください")
      expect(page).to have_content("パスワード（確認）とパスワードの入力が一致しません")
    end
  end
  
  describe "Login" do
    it "allows a registered user to log in" do
      visit login_path
      
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "password"
      
      click_button "ログイン"
      
      expect(page).to have_content("ログインしました")
      expect(page).to have_current_path(root_path)
    end
    
    it "shows an error with invalid credentials" do
      visit login_path
      
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "wrong_password"
      
      click_button "ログイン"
      
      expect(page).to have_content("ログインに失敗しました")
      expect(page).to have_current_path(login_path)
    end
  end
  
  describe "Logout" do
    it "allows a logged in user to log out" do
      # Log in first
      visit login_path
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
      
      # Then log out
      find('i.bi-box-arrow-right').click
      
      expect(page).to have_content("ログアウトしました")
      expect(page).to have_current_path(root_path)
    end
  end
  
  describe "Profile editing" do
    it "allows a logged in user to edit their profile" do
      # Log in first
      visit login_path
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
      
      # Go to profile edit page
      visit edit_user_path(user)
      
      fill_in "お名前", with: "Updated Name"
      fill_in "メールアドレス", with: "updated@example.com"
      
      click_button "更新"
      
      expect(page).to have_content("プロフィールを更新しました")
      
      # Check that the user data was updated
      user.reload
      expect(user.name).to eq("Updated Name")
      expect(user.email).to eq("updated@example.com")
    end
  end
end
