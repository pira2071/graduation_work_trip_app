require 'rails_helper'

RSpec.describe "TravelItinerary", type: :system, js: true do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user, start_date: Date.current, end_date: Date.current + 3.days) }
  
  before do
    # Create travel membership
    create(:travel_member, travel: travel, user: user, role: :organizer)
    
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
  end
  
  describe "Itinerary page" do
    it "displays the itinerary page with Google Maps" do
      visit new_travel_spot_path(travel)
      
      expect(page).to have_content("旅のしおり")
      expect(page).to have_css('#map')
      expect(page).to have_css('#pac-input')
      
      # Category sections should be visible
      expect(page).to have_content("観光スポット")
      expect(page).to have_content("食事処")
      expect(page).to have_content("宿泊先")
      
      # Day sections should be visible
      expect(page).to have_content("1日目")
      expect(page).to have_content("2日目")
      expect(page).to have_content("3日目")
      expect(page).to have_content("4日目")
      
      # Time zone sections should be visible
      expect(page).to have_content("朝")
      expect(page).to have_content("昼")
      expect(page).to have_content("夜")
    end
  end
  
  # Note: The following tests would normally rely on JavaScript interaction,
  # which is difficult to test reliably in system specs without proper setup.
  # In a real application, these would be more comprehensive.
  
  describe "Spot management" do
    it "has spot registration buttons" do
      visit new_travel_spot_path(travel)
      
      expect(page).to have_button("観光登録")
      expect(page).to have_button("食事処登録")
      expect(page).to have_button("宿泊先登録")
    end
  end
  
  describe "Itinerary planning" do
    # For schedules
    it "has schedule containers for each day and time zone" do
      visit new_travel_spot_path(travel)
      
      # Check for schedule containers
      (1..4).each do |day|
        expect(page).to have_css("[data-day='#{day}'][data-time-zone='morning']")
        expect(page).to have_css("[data-day='#{day}'][data-time-zone='noon']")
        expect(page).to have_css("[data-day='#{day}'][data-time-zone='night']")
      end
    end
    
    it "has a save button for the itinerary" do
      visit new_travel_spot_path(travel)
      
      expect(page).to have_button("保存")
    end
    
    it "has a notification dropdown" do
      visit new_travel_spot_path(travel)
      
      expect(page).to have_button("メンバーに通知")
      # This would require JavaScript interaction to test fully
    end
  end
end
