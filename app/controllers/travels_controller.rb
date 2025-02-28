class TravelsController < ApplicationController
  before_action :set_travel, only: %i[show edit update destroy]

  def index
    @q = current_user.all_travels.ransack(params[:q])
    @travels = @q.result(distinct: true).includes(:user)
  
    respond_to do |format|
      format.html
      format.json { 
        Rails.logger.debug "Search params: #{params[:q]}" # 検索パラメータ確認用
        Rails.logger.debug "Search results: #{@travels.map(&:title)}" # 検索結果確認用
        render json: @travels.map { |travel| 
          { 
            id: travel.id, 
            title: travel.title 
          } 
        } 
      }
    end
  end

  def show
    @travel = Travel.includes(:user, travel_members: :user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: 'プランが見つかりませんでした'
    Rails.logger.debug "Travel ID: #{@travel.id}"
    Rails.logger.debug "Notifications: #{@travel.notifications.map(&:action)}"
    Rails.logger.debug "Shared?: #{@travel.shared?}"
    Rails.logger.debug "Is Planner?: #{@travel.user_id == current_user.id}"
  end

  def new
    @travel = Travel.new
    @friends = current_user.friends  # 友達リストを取得
  end
  
  def edit
    @travel = current_user.organized_travels.find(params[:id])
    @friends = current_user.friends  # 友達リストを取得
  end
  
  def create
    @travel = current_user.organized_travels.build(travel_params)
    if @travel.save
      # 作成者をorganizer roleで登録
      @travel.travel_members.create!(user: current_user, role: :organizer)
  
      # 選択されたメンバーを登録
      if params[:member_ids].present?
        params[:member_ids].each do |member_id|
          user = User.find(member_id)
          @travel.travel_members.create(user: user, role: :guest)
        end
      end
  
      redirect_to travels_path, success: 'プランを作成しました'
    else
      @friends = current_user.friends
      flash.now[:danger] = 'プランの作成に失敗しました'
      render :new, status: :unprocessable_entity
    end
  end
  
  def update
    @travel = current_user.organized_travels.find(params[:id])
    if @travel.update(travel_params)
      # メンバーの更新処理
      @travel.travel_members.where(role: :guest).destroy_all
      
      if params[:member_ids].present?
        params[:member_ids].each do |member_id|
          user = User.find(member_id)
          @travel.travel_members.create(user: user, role: :guest)
        end
      end
  
      redirect_to @travel, success: 'プランを更新しました'
    else
      @friends = current_user.friends
      flash.now[:danger] = 'プランの更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @travel = current_user.organized_travels.find(params[:id])
    @travel.destroy!
    redirect_to travels_path, status: :see_other, success: 'プランを削除しました'
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: 'プランが見つかりませんでした'
  end

  private

  def set_travel
    @travel = Travel.includes(:user, travel_members: :user)
                   .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: 'プランが見つかりませんでした'
  end

  def travel_params
    params.require(:travel).permit(:title, :start_date, :end_date, :thumbnail, :member_names)
  end
end
