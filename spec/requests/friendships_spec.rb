require 'rails_helper'

RSpec.describe "Friendships", type: :request do
  let(:user) { create(:user) }
  let(:friend) { create(:user) }
  
  describe "GET /friendships" do
    context "when logged in" do
      before { login_user(user) }
      
      it "displays the friendships index page" do
        get friendships_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("フレンド一覧")
      end
      
      context "with existing friends" do
        before do
          create(:friendship, requester: user, receiver: friend, status: 'accepted')
        end
        
        it "shows the friends" do
          get friendships_path
          expect(response.body).to include(friend.name)
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get friendships_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "GET /friend_requests" do
    context "when logged in" do
      before { login_user(user) }
      
      it "displays the friend requests page" do
        get friend_requests_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("フレンド追加")
      end
      
      context "with pending friend requests" do
        before do
          create(:friendship, requester: friend, receiver: user, status: 'pending')
        end
        
        it "shows the pending requests" do
          get friendships_path
          expect(response.body).to include(friend.name)
          expect(response.body).to include("承認")
          expect(response.body).to include("拒否")
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get friend_requests_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /friendships" do
    context "when logged in" do
      before { login_user(user) }
      
      context "with valid name" do
        it "creates a new friendship" do
          expect {
            post friendships_path, params: { name: friend.name }
          }.to change(Friendship, :count).by(1)
          
          expect(response).to redirect_to(friend_requests_path)
          follow_redirect!
          expect(response.body).to include("フレンド申請を送信しました")
        end
      end
      
      context "with invalid name" do
        it "redirects back with error message" do
          expect {
            post friendships_path, params: { name: "NonExistentUser" }
          }.not_to change(Friendship, :count)
          
          expect(response).to redirect_to(friend_requests_path)
          follow_redirect!
          expect(response.body).to include("実行できませんでした")
        end
      end
      
      context "when trying to add self as friend" do
        it "redirects back with error message" do
          expect {
            post friendships_path, params: { name: user.name }
          }.not_to change(Friendship, :count)
          
          expect(response).to redirect_to(friend_requests_path)
          follow_redirect!
          expect(response.body).to include("自分自身に友達申請はできません")
        end
      end
      
      context "when already friends" do
        before do
          create(:friendship, requester: user, receiver: friend, status: 'accepted')
        end
        
        it "redirects back with error message" do
          expect {
            post friendships_path, params: { name: friend.name }
          }.not_to change(Friendship, :count)
          
          expect(response).to redirect_to(friend_requests_path)
          follow_redirect!
          expect(response.body).to include("すでに友達です")
        end
      end
      
      context "when friend request already exists" do
        before do
          create(:friendship, requester: user, receiver: friend, status: 'pending')
        end
        
        it "redirects back with error message" do
          expect {
            post friendships_path, params: { name: friend.name }
          }.not_to change(Friendship, :count)
          
          expect(response).to redirect_to(friend_requests_path)
          follow_redirect!
          expect(response.body).to include("すでに友達申請が存在します")
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        post friendships_path, params: { name: friend.name }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "PATCH /friendships/:id/accept" do
    let!(:friendship) { create(:friendship, requester: friend, receiver: user, status: 'pending') }
    
    context "when logged in" do
      before { login_user(user) }
      
      it "accepts the friendship request" do
        patch accept_friendship_path(friendship)
        
        friendship.reload
        expect(friendship.status).to eq('accepted')
        expect(friendship.accepted_at).to be_present
        
        expect(response).to redirect_to(friendships_path)
        follow_redirect!
        expect(response.body).to include("フレンド申請を承認しました")
      end
      
      it "creates a notification" do
        expect {
          patch accept_friendship_path(friendship)
        }.to change(Notification, :count).by(1)
        
        notification = Notification.last
        expect(notification.recipient).to eq(friend)
        expect(notification.action).to eq('friend_request_accepted')
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        patch accept_friendship_path(friendship)
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "PATCH /friendships/:id/reject" do
    let!(:friendship) { create(:friendship, requester: friend, receiver: user, status: 'pending') }
    
    context "when logged in" do
      before { login_user(user) }
      
      it "rejects the friendship request" do
        patch reject_friendship_path(friendship)
        
        friendship.reload
        expect(friendship.status).to eq('rejected')
        expect(friendship.rejected_at).to be_present
        
        expect(response).to redirect_to(friendships_path)
        follow_redirect!
        expect(response.body).to include("フレンド申請を拒否しました")
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        patch reject_friendship_path(friendship)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
