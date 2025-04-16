require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:notification) { create(:notification, recipient: user) }

  describe "GET /notifications" do
    context "when logged in" do
      before { login_user(user) }

      it "returns JSON data of user notifications" do
        notification # Create the notification

        get notifications_path, as: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json_response = JSON.parse(response.body)
        expect(json_response.size).to eq(1)
        expect(json_response.first["id"]).to eq(notification.id)
      end

      it "returns an empty array when no notifications exist" do
        get notifications_path, as: :json

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get notifications_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "DELETE /notifications/:id" do
    let!(:notification) { create(:notification, recipient: user) }

    context "when logged in" do
      before { login_user(user) }

      it "deletes the notification" do
        expect {
          delete notification_path(notification), as: :json
        }.to change(Notification, :count).by(-1)

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["success"]).to be_truthy
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        delete notification_path(notification)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /notifications/:id/mark_as_read" do
    let!(:notification) { create(:notification, recipient: user, read: false, read_at: nil) }

    context "when logged in" do
      before { login_user(user) }

      it "marks the notification as read" do
        post mark_as_read_notification_path(notification)

        notification.reload
        expect(notification.read_at).to be_present

        # Should redirect to the notification URL
        expect(response).to be_redirect
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        post mark_as_read_notification_path(notification)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
