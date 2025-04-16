require 'rails_helper'

RSpec.describe PackingListsController, type: :controller do
  let(:user) { create(:user) }
  let(:packing_list) { create(:packing_list, user: user) }

  describe 'GET #index' do
    context 'when logged in' do
      before do
        login_user(user)
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns @packing_lists' do
        expect(assigns(:packing_lists)).to eq(user.packing_lists.order(created_at: :desc))
      end
    end

    context 'when not logged in' do
      it 'redirects to login path' do
        get :index
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

      it 'assigns a new packing list to @packing_list' do
        expect(assigns(:packing_list)).to be_a_new(PackingList)
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
            packing_list: {
              name: 'Test Packing List',
              items: {
                '0' => 'Item 1',
                '1' => 'Item 2'
              }
            }
          }
        end

        it 'creates a new packing list' do
          expect {
            post :create, params: valid_params
          }.to change(PackingList, :count).by(1)
        end

        it 'creates packing items' do
          expect {
            post :create, params: valid_params
          }.to change(PackingItem, :count).by(2)
        end

        it 'redirects to packing_lists path' do
          post :create, params: valid_params
          expect(response).to redirect_to(packing_lists_path)
        end

        it 'sets success flash message' do
          post :create, params: valid_params
          expect(flash[:success]).to be_present
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            packing_list: {
              name: '',
              items: {}
            }
          }
        end

        it 'does not create a new packing list' do
          expect {
            post :create, params: invalid_params
          }.not_to change(PackingList, :count)
        end

        it 'renders new template' do
          post :create, params: invalid_params
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login path' do
        post :create, params: { packing_list: { name: 'Test' } }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'GET #show' do
    context 'when logged in' do
      before do
        login_user(user)
      end

      it 'returns http success' do
        get :show, params: { id: packing_list.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the requested packing list to @packing_list' do
        get :show, params: { id: packing_list.id }
        expect(assigns(:packing_list)).to eq(packing_list)
      end

      it 'assigns items to @items' do
        get :show, params: { id: packing_list.id }
        expect(assigns(:items)).to eq(packing_list.packing_items.order(:created_at))
      end
    end

    context 'when not logged in' do
      it 'redirects to login path' do
        get :show, params: { id: packing_list.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:packing_list) { create(:packing_list, user: user) }

    context 'when logged in' do
      before do
        login_user(user)
      end

      it 'destroys the packing list' do
        expect {
          delete :destroy, params: { id: packing_list.id }
        }.to change(PackingList, :count).by(-1)
      end

      it 'redirects to packing_lists path' do
        delete :destroy, params: { id: packing_list.id }
        expect(response).to redirect_to(packing_lists_path)
      end

      it 'sets success flash message' do
        delete :destroy, params: { id: packing_list.id }
        expect(flash[:success]).to be_present
      end
    end

    context 'when not logged in' do
      it 'redirects to login path' do
        delete :destroy, params: { id: packing_list.id }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
