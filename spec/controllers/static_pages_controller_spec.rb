require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do
  describe 'GET #top' do
    it 'returns http success' do
      get :top
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'GET #terms_of_service' do
    it 'returns http success' do
      get :terms_of_service
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'GET #privacy_policy' do
    it 'returns http success' do
      get :privacy_policy
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'GET #dashboard' do
    context 'when logged in' do
      let(:user) { create(:user) }
      
      before do
        login_user(user)
        get :dashboard
      end
      
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'when not logged in' do
      before do
        get :dashboard
      end
      
      it 'redirects to login path' do
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
