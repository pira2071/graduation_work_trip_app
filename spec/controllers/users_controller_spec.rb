require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            name: 'Test User',
            email: 'test@example.com',
            password: 'password',
            password_confirmation: 'password'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'logs in the user' do
        post :create, params: valid_params
        expect(controller.current_user).to be_present
      end

      it 'redirects to root path' do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it 'sets success flash message' do
        post :create, params: valid_params
        expect(flash[:success]).to be_present
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          user: {
            name: '',
            email: 'invalid_email',
            password: 'pass',
            password_confirmation: 'wrong'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
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

  describe 'GET #edit' do
    let(:user) { create(:user) }

    context 'when logged in' do
      before do
        login_user(user)
        get :edit, params: { id: user.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns the current user as @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when not logged in' do
      before do
        get :edit, params: { id: user.id }
      end

      it 'redirects to login path' do
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:user) { create(:user) }

    context 'when logged in' do
      before do
        login_user(user)
      end

      context 'with valid params' do
        let(:valid_update_params) do
          {
            id: user.id,
            user: {
              name: 'Updated Name',
              email: 'updated@example.com'
            }
          }
        end

        it 'updates the user' do
          patch :update, params: valid_update_params
          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.email).to eq('updated@example.com')
        end

        it 'redirects to root path' do
          patch :update, params: valid_update_params
          expect(response).to redirect_to(root_path)
        end

        it 'sets success flash message' do
          patch :update, params: valid_update_params
          expect(flash[:success]).to be_present
        end
      end

      context 'with invalid params' do
        let(:invalid_update_params) do
          {
            id: user.id,
            user: {
              name: '',
              email: 'invalid_email'
            }
          }
        end

        it 'does not update the user' do
          original_name = user.name
          original_email = user.email

          patch :update, params: invalid_update_params
          user.reload

          expect(user.name).to eq(original_name)
          expect(user.email).to eq(original_email)
        end

        it 'renders edit template' do
          patch :update, params: invalid_update_params
          expect(response).to render_template(:edit)
        end

        it 'sets danger flash message' do
          patch :update, params: invalid_update_params
          expect(flash[:danger]).to be_present
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login path' do
        patch :update, params: { id: user.id, user: { name: 'New Name' } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
