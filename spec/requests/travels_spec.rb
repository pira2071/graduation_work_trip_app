require 'rails_helper'

RSpec.describe "Travels", type: :request do
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user) }

  describe "GET /travels" do
    context "when logged in" do
      before { login_user(user) }

      it "displays the travels index page" do
        get travels_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("プラン一覧")
      end

      context "with search parameter" do
        before do
          create(:travel, user: user, title: "Test Travel")
        end

        it "returns matching travels" do
          get travels_path, params: { q: { title_cont: "Test" } }
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Test Travel")
        end

        it "returns JSON when requested" do
          get travels_path, params: { q: { title_cont: "Test" } }, headers: { "Accept" => "application/json" }
          expect(response.content_type).to include("application/json")
          expect(JSON.parse(response.body).first["title"]).to eq("Test Travel")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get travels_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /travels/:id" do
    context "when logged in" do
      before { login_user(user) }

      it "displays the travel details page" do
        get travel_path(travel)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(travel.title)
      end

      it "redirects to travels path for invalid ID" do
        get travel_path(9999)
        expect(response).to redirect_to(travels_path)
        expect(flash[:danger]).to be_present
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get travel_path(travel)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /travels/new" do
    context "when logged in" do
      before { login_user(user) }

      it "displays the new travel form" do
        get new_travel_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("プラン作成")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get new_travel_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /travels" do
    let(:valid_params) do
      {
        travel: {
          title: "New Travel",
          start_date: Date.current,
          end_date: Date.current + 3.days
        }
      }
    end

    context "when logged in" do
      before { login_user(user) }

      it "creates a new travel and redirects to travels path" do
        expect {
          post travels_path, params: valid_params
        }.to change(Travel, :count).by(1)
          .and change(TravelMember, :count).by(1)

        expect(response).to redirect_to(travels_path)
        follow_redirect!
        expect(response.body).to include("プランを作成しました")
      end

      context "with member_ids" do
        let(:friend1) { create(:user) }
        let(:friend2) { create(:user) }

        it "creates travel members for selected friends" do
          expect {
            post travels_path, params: valid_params.merge(member_ids: [ friend1.id, friend2.id ])
          }.to change(TravelMember, :count).by(3) # 1 organizer + 2 guests

          expect(TravelMember.where(role: 'guest').count).to eq(2)
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            travel: {
              title: "",
              start_date: nil,
              end_date: nil
            }
          }
        end

        it "does not create a travel and renders the new template" do
          expect {
            post travels_path, params: invalid_params
          }.not_to change(Travel, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("プラン作成")
          expect(response.body).to include("ユーザー登録に失敗しました")
        end
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        post travels_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /travels/:id/edit" do
    context "when logged in as the organizer" do
      before { login_user(user) }

      it "displays the edit travel form" do
        get edit_travel_path(travel)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("プラン編集")
        expect(response.body).to include(travel.title)
      end
    end

    context "when logged in as a non-organizer" do
      let(:other_user) { create(:user) }

      before { login_user(other_user) }

      it "redirects to travels path" do
        get edit_travel_path(travel)
        expect(response).to redirect_to(travels_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get edit_travel_path(travel)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /travels/:id" do
    let(:valid_params) do
      {
        travel: {
          title: "Updated Travel",
          start_date: Date.current + 1.day,
          end_date: Date.current + 4.days
        }
      }
    end

    context "when logged in as the organizer" do
      before { login_user(user) }

      it "updates the travel and redirects to travel page" do
        patch travel_path(travel), params: valid_params

        travel.reload
        expect(travel.title).to eq("Updated Travel")

        expect(response).to redirect_to(travel_path(travel))
        follow_redirect!
        expect(response.body).to include("プランが更新されました")
      end

      context "with member_ids" do
        let(:friend) { create(:user) }

        it "updates travel members" do
          patch travel_path(travel), params: valid_params.merge(member_ids: [ friend.id ])

          expect(travel.travel_members.where(role: 'guest').count).to eq(1)
          expect(travel.travel_members.where(role: 'guest').first.user_id).to eq(friend.id)
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            travel: {
              title: "",
              start_date: nil,
              end_date: nil
            }
          }
        end

        it "does not update the travel and renders the edit template" do
          original_title = travel.title

          patch travel_path(travel), params: invalid_params

          travel.reload
          expect(travel.title).to eq(original_title)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("プラン編集")
          expect(response.body).to include("更新に失敗しました")
        end
      end
    end

    context "when logged in as a non-organizer" do
      let(:other_user) { create(:user) }

      before { login_user(other_user) }

      it "redirects to travels path" do
        patch travel_path(travel), params: valid_params
        expect(response).to redirect_to(travels_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        patch travel_path(travel), params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "DELETE /travels/:id" do
    let!(:travel_to_delete) { create(:travel, user: user) }

    context "when logged in as the organizer" do
      before { login_user(user) }

      it "deletes the travel and redirects to travels path" do
        expect {
          delete travel_path(travel_to_delete)
        }.to change(Travel, :count).by(-1)

        expect(response).to redirect_to(travels_path)
        follow_redirect!
        expect(response.body).to include("プランを削除しました")
      end
    end

    context "when logged in as a non-organizer" do
      let(:other_user) { create(:user) }

      before { login_user(other_user) }

      it "does not delete the travel and redirects to travels path" do
        expect {
          delete travel_path(travel_to_delete)
        }.not_to change(Travel, :count)

        expect(response).to redirect_to(travels_path)
        expect(flash[:danger]).to be_present
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        delete travel_path(travel_to_delete)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
