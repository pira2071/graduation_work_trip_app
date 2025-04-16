require 'rails_helper'

RSpec.describe "UserAuthentication", type: :request do
  describe "GET /login" do
    it "displays the login page" do
      get login_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    let(:user) { create(:user) }

    context "with valid credentials" do
      it "logs in the user and redirects to root path" do
        post login_path, params: { email: user.email, password: 'password' }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("ログインしました")
      end
    end

    context "with invalid credentials" do
      it "renders the login page with error" do
        post login_path, params: { email: user.email, password: 'wrong_password' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("ログインに失敗しました")
      end
    end
  end

  describe "DELETE /logout" do
    let(:user) { create(:user) }

    it "logs out the user and redirects to root path" do
      login_user(user)

      delete logout_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("ログアウトしました")
    end
  end
end
