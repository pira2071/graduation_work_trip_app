require 'rails_helper'

RSpec.describe TravelsController, type: :controller do
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user) }
  
  describe 'GET #index' do
    context 'when logged in' do
      before do
        login_user(user)
        get :index
      end
      
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
      
      it 'assigns @travels' do
        expect(assigns(:travels)).to be_present
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
    
    context 'when requesting JSON format' do
      before do
        login_user(user)
        get :index, params: { q: { title_cont: travel.title } }, format: :json
      end
      
      it 'returns JSON data' do
        expect(response.content_type).to include('application/json')
      end
    end
  end
  
  describe 'GET #show' do
    context 'when logged in' do
      before do
        login_user(user)
      end
      
      context 'with valid travel ID' do
        before do
          get :show, params: { id: travel.id }
        end
        
        it 'returns http success' do
          expect(response).to have_http_status(:success)
        end
        
        it 'assigns @travel' do
          expect(assigns(:travel)).to eq(travel)
        end
      end
      
      context 'with invalid travel ID' do
        it 'redirects to travels path' do
          get :show, params: { id: 999 }
          expect(response).to redirect_to(travels_path)
        end
        
        it 'sets danger flash message' do
          get :show, params: { id: 999 }
          expect(flash[:danger]).to be_present
        end
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        get :show, params: { id: travel.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'GET #new' do
    context 'when logged in' do
      before do
        login_user(user)
        get :new
      end
      
      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end
      
      it 'assigns a new travel to @travel' do
        expect(assigns(:travel)).to be_a_new(Travel)
      end
      
      it 'assigns friends to @friends' do
        expect(assigns(:friends)).to eq(user.friends)
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        get :new
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'POST #create' do
    context 'when logged in' do
      before do
        login_user(user)
      end
      
      context 'with valid params' do
        let(:valid_params) do
          {
            travel: {
              title: 'Test Travel',
              start_date: Date.current,
              end_date: Date.current + 5.days
            }
          }
        end
        
        it 'creates a new travel' do
          expect {
            post :create, params: valid_params
          }.to change(Travel, :count).by(1)
        end
        
        it 'creates travel member for organizer' do
          expect {
            post :create, params: valid_params
          }.to change(TravelMember, :count).by(1)
          
          expect(TravelMember.last.role).to eq('organizer')
          expect(TravelMember.last.user).to eq(user)
        end
        
        it 'redirects to travels path' do
          post :create, params: valid_params
          expect(response).to redirect_to(travels_path)
        end
        
        it 'sets success flash message' do
          post :create, params: valid_params
          expect(flash[:success]).to be_present
        end
      end
      
      context 'with invalid params' do
        let(:invalid_params) do
          {
            travel: {
              title: '',
              start_date: nil,
              end_date: nil
            }
          }
        end
        
        it 'does not create a new travel' do
          expect {
            post :create, params: invalid_params
          }.not_to change(Travel, :count)
        end
        
        it 'renders new template' do
          post :create, params: invalid_params
          expect(response).to render_template(:new)
        end
        
        it 'sets danger flash message' do
          post :create, params: invalid_params
          expect(flash[:danger]).to be_present
        end
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        post :create, params: { travel: { title: 'Test' } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe 'DELETE #destroy' do
    let!(:travel) { create(:travel, user: user) }
    
    context 'when logged in as the organizer' do
      before do
        login_user(user)
      end
      
      it 'destroys the travel' do
        expect {
          delete :destroy, params: { id: travel.id }
        }.to change(Travel, :count).by(-1)
      end
      
      it 'redirects to travels path' do
        delete :destroy, params: { id: travel.id }
        expect(response).to redirect_to(travels_path)
      end
      
      it 'sets success flash message' do
        delete :destroy, params: { id: travel.id }
        expect(flash[:success]).to be_present
      end
    end
    
    context 'when logged in as a non-organizer' do
      let(:other_user) { create(:user) }
      
      before do
        login_user(other_user)
      end
      
      it 'does not destroy the travel' do
        expect {
          delete :destroy, params: { id: travel.id }
        }.not_to change(Travel, :count)
      end
      
      it 'redirects to travels path' do
        delete :destroy, params: { id: travel.id }
        expect(response).to redirect_to(travels_path)
      end
    end
    
    context 'when not logged in' do
      it 'redirects to login path' do
        delete :destroy, params: { id: travel.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
