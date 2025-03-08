require 'rails_helper'

RSpec.describe "PackingListManagement", type: :system do
  before do
    driven_by(:rack_test)
  end
  
  let(:user) { create(:user) }
  
  before do
    # Log in
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
  end
  
  describe "Packing list index" do
    it "displays the empty state when no lists exist" do
      visit packing_lists_path
      
      expect(page).to have_content("パックリスト")
      expect(page).to have_content("作成されたリストはありません")
      expect(page).to have_link("新規作成")
    end
    
    context "with existing packing lists" do
      before do
        create(:packing_list, user: user, name: "Beach Trip")
      end
      
      it "displays the list of packing lists" do
        visit packing_lists_path
        
        expect(page).to have_content("Beach Trip")
        expect(page).to have_button(class: 'delete-btn')
      end
    end
  end
  
  describe "Packing list creation" do
    it "allows creating a new packing list with items" do
      visit packing_lists_path
      click_link "新規作成"
      
      fill_in "リスト名", with: "Camping Trip"
      
      # Fill in the items
      all("input[name^='packing_list[items]']")[0].set("Tent")
      all("input[name^='packing_list[items]']")[1].set("Sleeping bag")
      all("input[name^='packing_list[items]']")[2].set("Flashlight")
      
      click_button "登録"
      
      expect(page).to have_content("持物リストを作成しました")
      expect(page).to have_content("Camping Trip")
    end
  end
  
  describe "Packing list details" do
    let!(:packing_list) { create(:packing_list, :with_items, user: user, name: "Travel Essentials") }
    
    it "displays the packing list items with checkboxes" do
      visit packing_list_path(packing_list)
      
      expect(page).to have_content("チェックリスト")
      expect(page).to have_content("Travel Essentials")
      
      # Check that all items are displayed
      packing_list.packing_items.each do |item|
        expect(page).to have_content(item.name)
        expect(page).to have_field("item_#{item.id}", type: 'checkbox')
      end
    end
  end
  
  describe "Packing list deletion" do
    let!(:packing_list) { create(:packing_list, user: user, name: "Travel Essentials") }
    
    it "allows deleting a packing list" do
      visit packing_lists_path
      
      accept_confirm do
        find('.delete-btn').click
      end
      
      expect(page).to have_content("持物リストを削除しました")
      expect(page).not_to have_content("Travel Essentials")
    end
  end
end
