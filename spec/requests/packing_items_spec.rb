require 'rails_helper'

RSpec.describe "PackingItems", type: :request do
  let(:user) { create(:user) }
  let(:packing_list) { create(:packing_list, user: user) }
  let(:packing_item) { create(:packing_item, packing_list: packing_list) }

  describe "PATCH /packing_lists/:packing_list_id/packing_items/:id" do
    context "when logged in" do
      before { login_user(user) }

      it "updates the packing item checked status" do
        patch packing_list_packing_item_path(packing_list, packing_item), params: { checked: true }

        packing_item.reload
        expect(packing_item.checked).to be_truthy

        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        patch packing_list_packing_item_path(packing_list, packing_item), params: { checked: true }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /packing_lists/:packing_list_id/packing_items/clear_all" do
    before do
      create(:packing_item, packing_list: packing_list, checked: true)
      create(:packing_item, packing_list: packing_list, checked: true)
    end

    context "when logged in" do
      before { login_user(user) }

      it "sets all packing items in the list to unchecked" do
        post clear_all_packing_list_packing_items_path(packing_list)

        expect(packing_list.packing_items.where(checked: true).count).to eq(0)
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        post clear_all_packing_list_packing_items_path(packing_list)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
