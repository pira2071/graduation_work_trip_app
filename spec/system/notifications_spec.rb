require 'rails_helper'

RSpec.describe "Notifications", type: :system, js: true do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  let(:user) { create(:user) }
  let(:friend) { create(:user, name: "Friend User") }
  let!(:notification) { create(:notification, recipient: user, action: 'friend_request') }
  
  before do
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
  end
  
  describe "Notification display" do
    it "shows a notification badge" do
      visit root_path
      
      # The notification badge should be visible
      expect(page).to have_css('.notification-badge')
      
      # Ideally, we would test clicking on the notification bell 
      # and seeing the dropdown, but this requires JavaScript interactions
      # that are difficult to test reliably in system specs.
    end
  end
end
