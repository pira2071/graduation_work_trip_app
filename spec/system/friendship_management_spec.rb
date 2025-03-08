require 'rails_helper'

RSpec.describe "FriendshipManagement", type: :system do
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  let(:friend) { create(:user, name: "Friend User") }
  
  before do
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
  end
  
  describe "Friend requests" do
    it "allows sending a friend request" do
      visit friend_requests_path
      
      fill_in "name", with: friend.name
      click_button "フレンド申請を送信"
      
      expect(page).to have_content("フレンド申請を送信しました")
    end
    
    it "prevents sending a friend request to non-existent user" do
      visit friend_requests_path
      
      fill_in "name", with: "Non Existent User"
      click_button "フレンド申請を送信"
      
      expect(page).to have_content("実行できませんでした")
    end
    
    it "prevents sending a friend request to self" do
      visit friend_requests_path
      
      fill_in "name", with: user.name
      click_button "フレンド申請を送信"
      
      expect(page).to have_content("自分自身に友達申請はできません")
    end
  end
  
  describe "Friendship management" do
    context "with pending friend requests" do
      before do
        create(:friendship, requester: friend, receiver: user, status: 'pending')
      end
      
      it "displays pending requests" do
        visit friendships_path
        
        expect(page).to have_content("保留中のリクエスト")
        expect(page).to have_content(friend.name)
        expect(page).to have_button("承認")
        expect(page).to have_button("拒否")
      end
      
      it "allows accepting a friend request" do
        visit friendships_path
        
        click_button "承認"
        
        expect(page).to have_content("フレンド申請を承認しました")
        
        # Friend should now be in the friends list
        expect(page).to have_content("すべてのフレンド")
        within('.friend-list') do
          expect(page).to have_content(friend.name)
        end
      end
      
      it "allows rejecting a friend request" do
        visit friendships_path
        
        click_button "拒否"
        
        expect(page).to have_content("フレンド申請を拒否しました")
        
        # Friend should not be in the friends list
        within('.friend-list') do
          expect(page).not_to have_content(friend.name)
        end
      end
    end
    
    context "with accepted friendships" do
      before do
        create(:friendship, requester: friend, receiver: user, status: 'accepted')
      end
      
      it "displays friends in the friends list" do
        visit friendships_path
        
        expect(page).to have_content("すべてのフレンド")
        expect(page).to have_content(friend.name)
      end
    end
  end
end
