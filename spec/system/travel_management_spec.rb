require 'rails_helper'

RSpec.describe "TravelManagement", type: :system do
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  let!(:travel) { create(:travel, user: user, title: "Tokyo Trip") }
  
  before do
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"

    # ログイン成功を確認
    expect(page).to have_content("ログインしました")
  end
  
  describe "Travels index" do
    it "displays the list of travels" do
      visit travels_path
      
      expect(page).to have_content("プラン一覧")
      expect(page).to have_content("Tokyo Trip")
    end
    
    it "allows searching for travels" do
      create(:travel, user: user, title: "Osaka Adventure")
      
      visit travels_path(q: { title_cont: "Tokyo" })
      
      expect(page).to have_content("Tokyo Trip")
      expect(page).not_to have_content("Osaka Adventure")
    end
  end
  
  describe "Travel creation" do
    it "allows creating a new travel" do
      visit travels_path
      click_link "新規作成"
      
      fill_in "タイトル", with: "New Adventure"
      fill_in "開始日", with: Date.current.strftime("%Y-%m-%d")
      fill_in "終了日", with: (Date.current + 3.days).strftime("%Y-%m-%d")
      
      click_button "作成"
      
      expect(page).to have_content("プランを作成しました")
      expect(page).to have_content("New Adventure")
    end
  end
  
  describe "Travel details" do
    it "displays travel details" do
      visit travel_path(travel)
      
      expect(page).to have_content(travel.title)
      expect(page).to have_content(travel.start_date.strftime('%Y年%m月%d日'))
      expect(page).to have_content(travel.end_date.strftime('%Y年%m月%d日'))
      expect(page).to have_content("幹事：#{user.name}")
    end
    
    it "navigates to travel itinerary" do
      # Create a membership first (organizer)
      create(:travel_member, travel: travel, user: user, role: :organizer)
      
      visit travel_path(travel)
      click_link "旅のしおり"
      
      expect(page).to have_current_path(new_travel_spot_path(travel))
      expect(page).to have_content("旅のしおり")
    end
  end
  
  describe "Travel editing" do
    # ファクトリの定義を明示的に修正
    let(:user) { create(:user) }
    let!(:travel) { create(:travel, user: user, title: "Tokyo Trip") }

    # 旅行詳細テスト
    it "allows the organizer to edit a travel" do
      visit travel_path(travel)
      
      # デバッグ情報
      puts "Current user ID: #{user.id}"
      puts "Travel user ID: #{travel.user_id}"
      puts "Page content: #{page.text}"
      
      # (あなた) がなくても直接編集リンクを探す
      click_link "編集" if page.has_link?("編集")
      # または
      find('a', text: '編集').click if page.has_css?('a', text: '編集')
      
      fill_in "タイトル", with: "Updated Trip"
      click_button "更新"
      
      expect(page).to have_content("プランが更新されました")
      expect(page).to have_content("Updated Trip")
    end
  end
  
  describe "Travel deletion" do
    it "allows the organizer to delete a travel" do
      visit travel_path(travel)
      
      # デバッグ情報
      puts "Current user ID: #{user.id}"
      puts "Travel user ID: #{travel.user_id}"
      puts "Page content: #{page.text}"
      
      # 直接削除リンクを探す
      accept_confirm do
        click_link "削除" if page.has_link?("削除")
        # または
        find('a', text: '削除').click if page.has_css?('a', text: '削除')
      end
      
      expect(page).to have_content("プランを削除しました")
      expect(page).not_to have_content("Tokyo Trip")
    end
  end
end
