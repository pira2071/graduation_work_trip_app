class TravelsController < ApplicationController
  before_action :set_travel, only: %i[show edit update destroy]

  def index
    @travels = current_user.travels.all
  end

  def show; end

  def new
    @travel = Travel.new
  end

  def create
    @travel = current_user.travels.build(travel_params)
    if @travel.save
      # 作成者をorganizer roleで登録
      @travel.travel_members.create!(user: current_user, role: :organizer)

      # メンバー名を保存
      if params[:travel][:member_names].present?
        member_names = params[:travel][:member_names].split('、').map(&:strip)
        member_names.each do |name|
          next if name.blank?
          @travel.travel_members.create(name: name, role: :guest)
        end
      end

      redirect_to travels_path, success: 'プランを作成しました'
    else
      flash.now[:danger] = 'プランの作成に失敗しました'
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @travel = current_user.travels.find(params[:id])
  end

  def update
    @travel = current_user.travels.find(params[:id])
    if @travel.update(travel_params)
      # メンバーの更新処理
      if params[:travel][:member_names].present?
        # 既存のゲストメンバーを削除
        @travel.travel_members.where(role: :guest).destroy_all
        
        # 新しいメンバーを追加
        member_names = params[:travel][:member_names].split('、').map(&:strip)
        member_names.each do |name|
          next if name.blank?
          @travel.travel_members.create(name: name, role: :guest)
        end
      end
  
      redirect_to @travel, success: 'プランを更新しました'
    else
      flash.now[:danger] = 'プランの更新に失敗しました'
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @travel = current_user.travels.find(params[:id])
    @travel.destroy!
    redirect_to travels_path, status: :see_other, success: 'プランを削除しました'
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: 'プランが見つかりませんでした'
  end

  private

  def set_travel
    @travel = current_user.travels.find(params[:id])
  end

  def travel_params
    params.require(:travel).permit(:title, :start_date, :end_date, :thumbnail, :member_names)
  end
end
