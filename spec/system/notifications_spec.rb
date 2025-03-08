require 'rails_helper'

RSpec.describe "Notifications", type: :system do
  # JavaScriptに依存しない部分のテストのために rack_test に変更
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  let(:friend) { create(:user, name: "Friend User") }
  
  describe "Notification functionality" do
    context "with friend request notification" do
      before do
        # フレンド申請の通知を作成
        friendship = create(:friendship, requester: friend, receiver: user, status: 'pending')
        create(:notification, recipient: user, notifiable: friendship, action: 'friend_request')
        
        # ログイン
        visit login_path
        fill_in "メールアドレス", with: user.email
        fill_in "パスワード", with: "password"
        click_button "ログイン"
      end
      
      it "shows notification API endpoint data" do
        # 通知APIエンドポイントを直接テスト
        visit notifications_path
        
        # JSONレスポンスをパース
        json_response = JSON.parse(page.body)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to be >= 1
        
        notification = json_response.first
        expect(notification).to have_key('id')
        expect(notification).to have_key('action')
        expect(notification).to have_key('message')
        expect(notification).to have_key('url')
        
        # フレンド申請の通知メッセージ
        expect(notification['action']).to eq('friend_request')
        expect(notification['message']).to include(friend.name)
        expect(notification['message']).to include('友達申請')
      end
    end
    
    context "with travel itinerary notification" do
      let(:travel) { create(:travel, user: user) }
      
      before do
        # トラベルメンバーシップを作成
        create(:travel_member, travel: travel, user: friend, role: :guest)
        
        # 旅程表の通知を作成
        create(:notification, recipient: friend, notifiable: travel, action: 'itinerary_proposed')
        
        # フレンドとしてログイン
        visit login_path
        fill_in "メールアドレス", with: friend.email
        fill_in "パスワード", with: "password"
        click_button "ログイン"
      end
      
      it "shows travel itinerary notification data" do
        # 通知APIエンドポイントを直接テスト
        visit notifications_path
        
        # JSONレスポンスをパース
        json_response = JSON.parse(page.body)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to be >= 1
        
        notification = json_response.first
        expect(notification['action']).to eq('itinerary_proposed')
        expect(notification['message']).to include('旅程表')
        expect(notification['url']).to include(travel_path(travel))
      end
      
      it "allows accessing travel itinerary from notification" do
        # TravelShareを作成して共有状態を設定
        create(:travel_share, travel: travel, notification_type: 'itinerary_proposed')
        
        # from_notification パラメータ付きで旅のしおりページにアクセス
        visit new_travel_spot_path(travel, from_notification: true)
        
        # 旅のしおりページが表示される（アクセス拒否されない）
        expect(page).to have_content('旅のしおり')
        expect(page).not_to have_content('旅のしおりは幹事が現在作成中です')
      end
    end
  end
  
  describe "Notification UI elements" do
    before do
      # 未読通知を作成
      create(:notification, recipient: user, action: 'friend_request', read_at: nil)
      
      # ログイン
      visit login_path
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
    end
    
    # 通知バッジのモックテスト
    it "shows notification elements in the header" do
      # 通知ベルボタンの存在確認
      # 実際のヘッダーHTMLを確認して適切なセレクタを使用
      header_html = get_after_login_header_html
      
      expect(header_html).to include('notification-btn')
      expect(header_html).to include('bi-bell')
      expect(header_html).to include('notification-badge')
    end
  end
  
  private
  
  # ヘッダーHTMLを取得するヘルパーメソッド
  def get_after_login_header_html
    # after_login_header パーシャルのHTMLを取得
    ApplicationController.render(
      partial: 'shared/after_login_header',
      locals: { current_user: user }
    )
  end
end
