require 'rails_helper'

RSpec.describe "Photos", type: :request do
  let(:user) { create(:user) }
  let(:travel) { create(:travel, user: user) }
  let(:photo) { create(:photo, travel: travel, user: user) }
  
  before do
    # Add user as a travel member
    create(:travel_member, travel: travel, user: user, role: :organizer)
  end
  
  describe "GET /travels/:travel_id/photos" do
    context "when logged in as a travel member" do
      before { login_user(user) }
      
      it "displays the photos index page" do
        get travel_photos_path(travel)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("フォトブック")
      end
      
      context "with existing photos" do
        before do
          create(:photo, travel: travel, user: user, day_number: 1)
        end
        
        it "shows the photos" do
          get travel_photos_path(travel)
          expect(response.body).to include("写真を追加")
        end
      end
    end
    
    context "when not a travel member" do
      let(:non_member) { create(:user) }
      
      before { login_user(non_member) }
      
      it "redirects to travels path with alert" do
        get travel_photos_path(travel)
        expect(response).to redirect_to(travels_path)
        expect(flash[:alert]).to be_present
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get travel_photos_path(travel)
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "GET /travels/:travel_id/photos/day" do
    context "when logged in as a travel member" do
      before do
        login_user(user)
        create(:photo, travel: travel, user: user, day_number: 2)
      end
      
      it "returns JSON data for the requested day" do
        get day_travel_photos_path(travel), params: { day_number: 2 }, as: :json
        
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)["photos"]).to be_present
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get day_travel_photos_path(travel), params: { day_number: 1 }
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /travels/:travel_id/photos" do
    let(:image_file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test_image.jpg'), 'image/jpeg') }
    
    context "when logged in as a travel member" do
      before { login_user(user) }
      
      it "creates a new photo" do
        expect {
          post travel_photos_path(travel), params: { photo: { image: image_file, day_number: 1 } }, as: :json
        }.to change(Photo, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(response.content_type).to include("application/json")
        expect(JSON.parse(response.body)["photo"]).to be_present
      end
      
      context "with invalid parameters" do
        it "returns error response" do
          expect {
            post travel_photos_path(travel), params: { photo: { day_number: 1 } }, as: :json
          }.not_to change(Photo, :count)
          
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
    
    context "when not logged in" do
      it "returns unauthorized status" do
        post travel_photos_path(travel), params: { photo: { image: image_file, day_number: 1 } }, as: :json
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "DELETE /travels/:travel_id/photos/:id" do
    let!(:photo) { create(:photo, travel: travel, user: user) }
    
    context "when logged in as the photo owner" do
      before { login_user(user) }
      
      it "deletes the photo" do
        expect {
          delete travel_photo_path(travel, photo)
        }.to change(Photo, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context "when logged in as another member" do
      let(:other_user) { create(:user) }
      
      before do
        create(:travel_member, travel: travel, user: other_user, role: :guest)
        login_user(other_user)
      end
      
      it "returns forbidden status" do
        expect {
          delete travel_photo_path(travel, photo)
        }.not_to change(Photo, :count)
        
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        delete travel_photo_path(travel, photo)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
