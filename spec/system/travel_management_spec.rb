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
    it "allows the organizer to edit a travel" do
      # 一覧画面から編集ボタンをクリック
      visit travels_path

      # デバッグ情報
      puts "Current path: #{page.current_path}"
      puts "Page content: #{page.text}"

      # 一覧画面の編集ボタンを探す
      within(".travel-card") do
        click_link "編集"
      end

      # 編集フォームの入力
      fill_in "タイトル", with: "Updated Trip"
      click_button "更新"

      # メッセージが変わっているので期待値を修正
      expect(page).to have_content("プランを更新しました")
      expect(page).to have_content("Updated Trip")
    end
  end

  describe "Travel deletion" do
    it "allows the organizer to delete a travel" do
      visit travels_path

      # デバッグ情報
      puts "Current path: #{page.current_path}"
      puts "Page content: #{page.text}"

      # rack_testドライバーではJavaScriptの確認ダイアログをサポートしていないため、
      # data-turbo-confirmを無視して直接削除を実行

      # 削除前の状態を確認
      expect(page).to have_content("Tokyo Trip")

      # 削除処理を直接実行
      travel_path = travel_path(travel)
      page.driver.submit(:delete, travel_path, {})

      # 削除後の状態を確認
      expect(page).to have_content("プランを削除しました")
      expect(page).not_to have_content("Tokyo Trip")
    end
  end
end
