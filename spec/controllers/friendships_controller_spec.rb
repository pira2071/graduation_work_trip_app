require 'rails_helper'

RSpec.describe FriendshipsController, type: :controller do
  let(:user) { create(:user) }
  let(:friend) { create(:user) }
  
  describe 'GET #index' do
    context 'when logged in' do
      before do
        login_user(user)
        get :index
      end
      
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
      
      it 'assigns @friends' do
        expect(assigns(:friends)).to eq(user.friends)
      end
      
      it 'assigns @pending_requests' do
        expect(assigns(:pending_requests)).to eq(user.pending_friend_requests)
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'GET #requests' do
    context 'when logged in' do
      before do
        login_user(user)
        get :requests
      end
      
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
      
      it 'assigns @pending_requests' do
        expect(assigns(:pending_requests)).to eq(user.pending_friend_requests)
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        get :requests
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'POST #create' do
    context 'when logged in' do
      before do
        login_user(user)
      end
      
      context 'with valid name' do
        it 'creates a new friendship' do
          expect {
            post :create, params: { name: friend.name }
          }.to change(Friendship, :count).by(1)
        end
        
        it 'creates a notification' do
          expect {
            post :create, params: { name: friend.name }
          }.to change(Notification, :count).by(1)
        end
        
        it 'redirects to friend_requests_path' do
          post :create, params: { name: friend.name }
          expect(response).to redirect_to(friend_requests_path)
        end
        
        it 'sets success flash message' do
          post :create, params: { name: friend.name }
          expect(flash[:success]).to be_present
        end
      end
      
      context 'with invalid name' do
        it 'does not create a friendship' do
          expect {
            post :create, params: { name: 'NonExistentUser' }
          }.not_to change(Friendship, :count)
        end
        
        it 'redirects to friend_requests_path' do
          post :create, params: { name: 'NonExistentUser' }
          expect(response).to redirect_to(friend_requests_path)
        end
        
        it 'sets error flash message' do
          post :create, params: { name: 'NonExistentUser' }
          expect(flash[:error]).to be_present
        end
      end
      
      context 'when trying to add self as friend' do
        it 'does not create a friendship' do
          expect {
            post :create, params: { name: user.name }
          }.not_to change(Friendship, :count)
        end
        
        it 'redirects to friend_requests_path' do
          post :create, params: { name: user.name }
          expect(response).to redirect_to(friend_requests_path)
        end
        
        it 'sets error flash message' do
          post :create, params: { name: user.name }
          expect(flash[:error]).to be_present
        end
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        post :create, params: { name: friend.name }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'PATCH #accept' do
    let!(:friendship) { create(:friendship, requester: friend, receiver: user) }
    
    context 'when logged in' do
      before do
        login_user(user)
      end
      
      it 'updates the friendship status to accepted' do
        patch :accept, params: { id: friendship.id }
        friendship.reload
        expect(friendship.status).to eq('accepted')
      end
      
      it 'creates a notification' do
        expect {
          patch :accept, params: { id: friendship.id }
        }.to change(Notification, :count).by(1)
      end
      
      it 'redirects to friendships path' do
        patch :accept, params: { id: friendship.id }
        expect(response).to redirect_to(friendships_path)
      end
      
      it 'sets notice flash message' do
        patch :accept, params: { id: friendship.id }
        expect(flash[:notice]).to be_present
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        patch :accept, params: { id: friendship.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'PATCH #reject' do
    let!(:friendship) { create(:friendship, requester: friend, receiver: user) }
    
    context 'when logged in' do
      before do
        login_user(user)
      end
      
      it 'updates the friendship status to rejected' do
        patch :reject, params: { id: friendship.id }
        friendship.reload
        expect(friendship.status).to eq('rejected')
      end
      
      it 'redirects to friendships path' do
        patch :reject, params: { id: friendship.id }
        expect(response).to redirect_to(friendships_path)
      end
      
      it 'sets notice flash message' do
        patch :reject, params: { id: friendship.id }
        expect(flash[:notice]).to be_present
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        patch :reject, params: { id: friendship.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
