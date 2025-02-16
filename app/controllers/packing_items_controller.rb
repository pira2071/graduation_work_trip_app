class PackingItemsController < ApplicationController
    before_action :set_packing_list
    before_action :set_item, only: [:update]
  
    def update
      if @item.update(checked: params[:checked])
        head :ok
      else
        head :unprocessable_entity
      end
    end
  
    def clear_all
      @packing_list.packing_items.update_all(checked: false)
      head :ok
    end
  
    private
  
    def set_packing_list
      @packing_list = current_user.packing_lists.find(params[:packing_list_id])
    end
  
    def set_item
      @item = @packing_list.packing_items.find(params[:id])
    end
  end
