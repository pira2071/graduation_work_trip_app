class PackingListsController < ApplicationController
  def index
    @packing_lists = current_user.packing_lists.order(created_at: :desc)
  end

  def new
    @packing_list = PackingList.new
  end
      
  def create
    @packing_list = current_user.packing_lists.build(packing_list_params)
    
    if @packing_list.save
      if params[:packing_list][:items].present?
        params[:packing_list][:items].each do |key, item_name|
          next if item_name.blank?
          @packing_list.packing_items.create!(name: item_name)
        end
      end
      
      redirect_to packing_lists_path, success: '持物リストを作成しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @packing_list = current_user.packing_lists.find(params[:id])
    @items = @packing_list.packing_items.order(:created_at)
  end
    
  private
    
  def packing_list_params
    params.require(:packing_list).permit(:name)
  end
    
  def items_params
    params.require(:packing_list).permit(items: [])
  end
end
