require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "displays the registration page" do
      get new_user_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("新規ユーザー登録")
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            name: "Test User",
            email: "test@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }
      end

      it "creates a new user and redirects to root path" do
        expect {
          post users_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("アカウントを作成しました")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            name: "",
            email: "invalid",
            password: "pass",
            password_confirmation: "different"
          }
        }
      end

      it "does not create a user and renders the new template" do
        expect {
          post users_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("ユーザー登録に失敗しました")
      end
    end
  end

  describe "GET /users/:id/edit" do
    let(:user) { create(:user) }

    context "when logged in" do
      before { login_user(user) }

      it "displays the edit profile page" do
        get edit_user_path(user)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("プロフィール編集")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get edit_user_path(user)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /users/:id" do
    let(:user) { create(:user) }

    context "when logged in" do
      before { login_user(user) }

      context "with valid parameters" do
        let(:valid_params) do
          {
            user: {
              name: "Updated Name",
              email: "updated@example.com"
            }
          }
        end

        it "updates the user and redirects to root path" do
          patch user_path(user), params: valid_params

          user.reload
          expect(user.name).to eq("Updated Name")
          expect(user.email).to eq("updated@example.com")

          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("プロフィールを更新しました")
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            user: {
              name: "",
              email: "invalid"
            }
          }
        end

        it "does not update the user and renders the edit template" do
          original_name = user.name
          original_email = user.email

          patch user_path(user), params: invalid_params

          user.reload
          expect(user.name).to eq(original_name)
          expect(user.email).to eq(original_email)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("プロフィール編集")
          expect(response.body).to include("更新に失敗しました")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        patch user_path(user), params: { user: { name: "New Name" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
