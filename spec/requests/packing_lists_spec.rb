require 'rails_helper'

RSpec.describe "PackingLists", type: :request do
  let(:user) { create(:user) }
  let(:packing_list) { create(:packing_list, user: user) }
  
  describe "GET /packing_lists" do
    context "when logged in" do
      before { login_user(user) }
      
      it "displays the packing lists index page" do
        get packing_lists_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("パックリスト")
      end
      
      context "with existing packing lists" do
        before do
          create(:packing_list, user: user, name: "Travel Essentials")
        end
        
        it "shows the packing lists" do
          get packing_lists_path
          expect(response.body).to include("Travel Essentials")
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get packing_lists_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "GET /packing_lists/new" do
    context "when logged in" do
      before { login_user(user) }
      
      it "displays the new packing list form" do
        get new_packing_list_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("リスト登録")
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get new_packing_list_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "POST /packing_lists" do
    let(:valid_params) do
      {
        packing_list: {
          name: "Beach Trip",
          items: {
            "0" => "Sunscreen",
            "1" => "Towel",
            "2" => "Sunglasses"
          }
        }
      }
    end
    
    context "when logged in" do
      before { login_user(user) }
      
      it "creates a new packing list with items" do
        expect {
          post packing_lists_path, params: valid_params
        }.to change(PackingList, :count).by(1)
          .and change(PackingItem, :count).by(3)
        
        expect(response).to redirect_to(packing_lists_path)
        follow_redirect!
        expect(response.body).to include("持物リストを作成しました")
      end
      
      context "with invalid parameters" do
        let(:invalid_params) do
          {
            packing_list: {
              name: "",
              items: {}
            }
          }
        end
        
        it "does not create a packing list and renders the new template" do
          expect {
            post packing_lists_path, params: invalid_params
          }.not_to change(PackingList, :count)
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("リスト登録")
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        post packing_lists_path, params: valid_params
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "GET /packing_lists/:id" do
    let(:packing_list_with_items) { create(:packing_list, :with_items, user: user) }
    
    context "when logged in" do
      before { login_user(user) }
      
      it "displays the packing list details page" do
        get packing_list_path(packing_list_with_items)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("チェックリスト")
        expect(response.body).to include(packing_list_with_items.name)
        
        # Items should be displayed
        packing_list_with_items.packing_items.each do |item|
          expect(response.body).to include(item.name)
        end
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        get packing_list_path(packing_list)
        expect(response).to redirect_to(login_path)
      end
    end
  end
  
  describe "DELETE /packing_lists/:id" do
    let!(:packing_list_to_delete) { create(:packing_list, user: user) }
    
    context "when logged in" do
      before { login_user(user) }
      
      it "deletes the packing list and redirects to packing lists path" do
        expect {
          delete packing_list_path(packing_list_to_delete)
        }.to change(PackingList, :count).by(-1)
        
        expect(response).to redirect_to(packing_lists_path)
        follow_redirect!
        expect(response.body).to include("持物リストを削除しました")
      end
    end
    
    context "when not logged in" do
      it "redirects to login page" do
        delete packing_list_path(packing_list_to_delete)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
