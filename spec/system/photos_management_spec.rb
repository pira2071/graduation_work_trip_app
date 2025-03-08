require 'rails_helper'

RSpec.describe "PhotosManagement", type: :system do
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user, start_date: Date.current, end_date: Date.current + 2.days) }
  
  before do
    # Create travel membership
    create(:travel_member, travel: travel, user: user, role: :organizer)
    
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
  end
  
  describe "Photos index" do
    it "displays the photos index page" do
      visit travel_photos_path(travel)
      
      expect(page).to have_content("フォトブック")
      
      # Should have day cards for each day of the trip
      expect(page).to have_content("1日目")
      expect(page).to have_content("2日目")
      expect(page).to have_content("3日目")
      
      # Each day should have an upload button
      expect(page).to have_css('label.btn-primary', text: '写真を追加', count: 3)
    end
    
    context "with existing photos" do
      before do
        create(:photo, travel: travel, user: user, day_number: 1)
      end
      
      it "displays photos for the relevant day" do
        visit travel_photos_path(travel)
        
        # Should display photos in the grid
        expect(page).to have_css('.photo-container')
        expect(page).to have_css('.photo-container img')
      end
    end
  end
  
  # Photo upload and deletion would typically require JavaScript testing
  # which is more complex in system tests
end
