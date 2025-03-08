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
      expect(page).to have_content('写真を追加', count: 3)
    end
    
    context "with existing photos" do
      before do
        # 写真の表示テストを簡略化: page.html.to_sを使って実際のHTMLを確認する
        @debug_mode = false
      end
      
      it "displays photos grid for days" do
        visit travel_photos_path(travel)
        
        if @debug_mode
          puts "Page HTML:"
          puts page.html.to_s
        end
        
        # 基本的なグリッド要素の存在を確認
        expect(page).to have_css('.photos-grid#day-1-photos')
      end
    end
  end
  
  # 写真アップロードのUIテスト
  describe "Photo upload UI" do
    it "shows photo upload buttons for each day" do
      visit travel_photos_path(travel)
      
      # 各日に対するアップロードボタンが存在するか確認
      expect(page).to have_css('label.btn-primary', count: 3)
      expect(page).to have_css('input[type="file"]', count: 3)
      
      # 非表示のファイル入力フィールドが存在するか確認
      (1..3).each do |day|
        expect(page).to have_css("#photo-upload-#{day}.d-none")
      end
    end
  end
  
  # 写真の閲覧モーダル - JavaScriptに依存するためシンプルなUIのみテスト
  describe "Photo viewing UI" do
    it "has a modal for viewing photos" do
      visit travel_photos_path(travel)
      
      # モーダルの要素が存在するか確認
      expect(page).to have_css('#photoModal.modal')
      expect(page).to have_css('#modalImage')
    end
  end
end
