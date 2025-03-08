require 'rails_helper'

RSpec.describe "Spots", type: :request do
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user) }
  let(:spot) { create(:spot, travel: travel) }
  
  before do
    # Add user as a travel member (organizer)
    create(:travel_member, travel: travel, user: user, role: :organizer)
  end
  
  describe "GET /travels/:travel_id/spots/new" do
    context "when logged in as the travel organizer" do
      before { login_user(user) }
      
      it "displays the spots page (travel itinerary)" do
        get new_travel_spot_path(travel)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("旅のしおり")
        expect(response.body).to include("Google Maps")
      end
    end
    
    context "when logged in as a travel member (guest)" do
      let(:guest_user) { create(:user) }
      
      before do
        create(:travel_member, travel: travel, user: guest_user, role: :guest)
        login_user(guest_user)
      end
      
      context "when travel is not shared" do
        it "redirects to travel path with warning" do
          get new_travel_spot_path(travel)
          expect(response).to redirect_to(travel_path(travel))
          expect(flash[:warning]).to be_present
          expect(flash[:warning]).to include("幹事が現在作成中です")
        end
      end
      
      context "when travel is shared" do
        before do
          create(:travel_share, travel: travel)
        end
        
        it "displays the spots page" do
          get new_travel_spot_path(travel)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("旅のしおり")
        end
      end
      
      context "when access from notification" do
        it "displays the spots page regardless of share status" do
          get new_travel_spot_path(travel, from_notification: true)
          expect(response).to have_http_status(:success)
          expect(response.body).to include("旅のしおり")
        end
      end
    end
    
    context "when not a travel member" do
      let(:non_member) { create(:user) }
      
      before { login_user(non_member) }
      
      it "redirects to travels path with alert" do
        get new_travel_spot_path(travel)
        expect(response).to redirect_to(travels_path)
        expect(flash[:alert]).to be_present
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get new_travel_spot_path(travel)
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /travels/:travel_id/spots/register" do
    let(:valid_spot_params) do
      {
        spot: {
          name: "Tokyo Tower",
          category: "sightseeing",
          lat: 35.6586,
          lng: 139.7454,
          order_number: 1
        }
      }
    end
    
    context "when logged in as a travel member" do
      before { login_user(user) }
      
      it "creates a new spot" do
        expect {
          post register_travel_spots_path(travel), params: valid_spot_params, as: :json
        }.to change(Spot, :count).by(1)
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)["success"]).to be_truthy
      end
      
      context "with duplicate spot name and category" do
        before do
          create(:spot, travel: travel, name: "Tokyo Tower", category: "sightseeing")
        end
        
        it "replaces the existing spot" do
          expect {
            post register_travel_spots_path(travel), params: valid_spot_params, as: :json
          }.not_to change(Spot, :count)
          
          expect(response).to have_http_status(:success)
        end
      end
      
      context "with invalid parameters" do
        let(:invalid_params) do
          {
            spot: {
              name: "",
              category: "",
              lat: nil,
              lng: nil,
              order_number: nil
            }
          }
        end
        
        it "returns error response" do
          expect {
            post register_travel_spots_path(travel), params: invalid_params, as: :json
          }.not_to change(Spot, :count)
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["success"]).to be_falsey
        end
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized status" do
        post register_travel_spots_path(travel), params: valid_spot_params, as: :json
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "PATCH /travels/:travel_id/spots/:id/update_order" do
    let(:spot) { create(:spot, travel: travel, order_number: 1) }
    
    context "when logged in as a travel member" do
      before { login_user(user) }
      
      it "updates the spot order number" do
        patch update_order_travel_spot_path(travel, spot), params: { order_number: 2 }, as: :json
        
        spot.reload
        expect(spot.order_number).to eq(2)
        
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["success"]).to be_truthy
      end
      
      context "with invalid order number" do
        it "returns error response" do
          patch update_order_travel_spot_path(travel, spot), params: { order_number: nil }, as: :json
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["success"]).to be_falsey
        end
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized status" do
        patch update_order_travel_spot_path(travel, spot), params: { order_number: 2 }, as: :json
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /travels/:travel_id/spots/save_schedules" do
    let!(:spot1) { create(:spot, travel: travel) }
    let!(:spot2) { create(:spot, travel: travel) }
    
    let(:valid_schedule_params) do
      {
        schedules: [
          {
            spot_id: spot1.id,
            day_number: 1,
            time_zone: "morning",
            order_number: 1
          },
          {
            spot_id: spot2.id,
            day_number: 1,
            time_zone: "noon",
            order_number: 1
          }
        ]
      }
    end
    
    context "when logged in as a travel member" do
      before { login_user(user) }
      
      it "creates schedules for the spots" do
        expect {
          post save_schedules_travel_spots_path(travel), params: valid_schedule_params, as: :json
        }.to change(Schedule, :count).by(2)
        
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["success"]).to be_truthy
      end
      
      context "with deleted spot IDs" do
        let(:params_with_deletion) do
          valid_schedule_params.merge(deleted_spot_ids: [spot2.id])
        end
        
        it "deletes the specified spots" do
          expect {
            post save_schedules_travel_spots_path(travel), params: params_with_deletion, as: :json
          }.to change(Spot, :count).by(-1)
            .and change(Schedule, :count).by(1)
          
          expect(response).to have_http_status(:success)
          expect(Spot.exists?(spot2.id)).to be_falsey
        end
      end
      
      context "with empty schedules" do
        it "clears all schedules" do
          # First create some schedules
          post save_schedules_travel_spots_path(travel), params: valid_schedule_params, as: :json
          
          # Then clear them
          expect {
            post save_schedules_travel_spots_path(travel), params: { schedules: [] }, as: :json
          }.to change(Schedule, :count).by(-2)
          
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["success"]).to be_truthy
        end
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized status" do
        post save_schedules_travel_spots_path(travel), params: valid_schedule_params, as: :json
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /travels/:travel_id/spots/create_notification" do
    context "when logged in as the travel organizer" do
      before { login_user(user) }
      
      it "creates notifications for all travel members" do
        guest = create(:user)
        create(:travel_member, travel: travel, user: guest, role: :guest)
        
        expect {
          post create_notification_travel_spots_path(travel), params: { notification_type: "itinerary_proposed" }, as: :json
        }.to change(Notification, :count).by(1)
          .and change(TravelShare, :count).by(1)
        
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["success"]).to be_truthy
        
        # Check that travel is marked as shared
        expect(travel.shared?).to be_truthy
      end
      
      it "supports different notification types" do
        guest = create(:user)
        create(:travel_member, travel: travel, user: guest, role: :guest)
        
        notification_types = ["itinerary_proposed", "itinerary_modified", "itinerary_confirmed"]
        
        notification_types.each do |notification_type|
          post create_notification_travel_spots_path(travel), params: { notification_type: notification_type }, as: :json
          
          notification = Notification.last
          expect(notification.action).to eq(notification_type)
          expect(response).to have_http_status(:success)
        end
      end
    end
    
    context "when logged in as a guest member" do
      let(:guest_user) { create(:user) }
      
      before do
        create(:travel_member, travel: travel, user: guest_user, role: :guest)
        login_user(guest_user)
      end
      
      it "returns unauthorized status" do
        post create_notification_travel_spots_path(travel), params: { notification_type: "itinerary_proposed" }, as: :json
        expect(response).to redirect_to(travels_path)
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized status" do
        post create_notification_travel_spots_path(travel), params: { notification_type: "itinerary_proposed" }, as: :json
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
