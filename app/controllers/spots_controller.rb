class SpotsController < ApplicationController
  include SchedulesHelper

  before_action :set_travel
  before_action :check_member
  
  def new
    @is_planner = @travel.user_id == current_user.id
    is_from_notification = params[:from_notification].present?

    is_shared = @travel.shared?

    unless @is_planner || is_shared || is_from_notification
      flash[:warning] = "旅のしおりは幹事が現在作成中です。"
      redirect_to travel_path(@travel)
      return
    end
    
    # @spotsの取得
    @spots = @travel.spots.includes(:schedule).order(:category, :order_number)
    
    # @schedulesの取得
    @schedules = @travel.spots.includes(:schedule)
                       .where.not(schedules: { id: nil })
                       .order('schedules.day_number ASC, schedules.time_zone ASC, schedules.order_number ASC')
                       .to_a  # 明示的に配列に変換
    
    @total_days = (@travel.end_date - @travel.start_date).to_i + 1
    
    # JSONデータの準備
    @spots_json = @spots.map do |spot|
      {
        id: spot.id,
        name: spot.name,
        category: spot.category,
        lat: spot.lat.to_f,
        lng: spot.lng.to_f,
        travel_id: @travel.id,
        schedule: spot.schedule ? {
          id: spot.schedule.id,
          day_number: spot.schedule.day_number,
          time_zone: spot.schedule.time_zone,
          order_number: spot.schedule.order_number
        } : nil
      }
    end

    # レビューの取得
    @reviews = @travel.travel_reviews.includes(:user).order(created_at: :desc)
  end

  def register
    @travel = Travel.find(params[:travel_id])
    
    # トランザクションを使用して一連の処理を保証
    ActiveRecord::Base.transaction do
      # 既存のスポットを物理削除（論理削除ではなく）
      @travel.spots.where(
        name: spot_params[:name],
        category: spot_params[:category]
      ).destroy_all
      
      # 新規スポットを作成
      @spot = @travel.spots.build(spot_params)
      
      if @spot.save
        render json: { 
          success: true, 
          spot: @spot.as_json.merge(travel_id: @travel.id),
          message: t('notices.spot.created')
        }
      else
        raise ActiveRecord::Rollback
        render json: { 
          success: false, 
          errors: @spot.errors.full_messages,
          message: t('activerecord.errors.models.spot.registration_failed')
        }, status: :unprocessable_entity
      end
    end
  end

  def update_order
    @spot = Spot.find(params[:id])
    if @spot.update(order_number: params[:order_number])
      render json: { success: true }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  def save_schedules
    @travel = Travel.find(params[:travel_id])
    schedules_params = params.require(:schedules).map do |schedule|
      schedule.permit(:spot_id, :day_number, :time_zone, :order_number)
    end rescue []  # パラメータが空の場合は空配列を返す
    
    deleted_spot_ids = params[:deleted_spot_ids] || []
  
    begin
      ActiveRecord::Base.transaction do
        # 既存のスケジュールを削除
        Schedule.where(spot_id: @travel.spot_ids).destroy_all
  
        # 削除予定のスポットを削除
        if deleted_spot_ids.any?
          @travel.spots.where(id: deleted_spot_ids).destroy_all
        end
  
        # 新しいスケジュールを作成（スケジュールパラメータがある場合のみ）
        if schedules_params.present?
          schedules_params.each do |schedule_param|
            spot = @travel.spots.find_by(id: schedule_param[:spot_id])
            if spot
              Schedule.create!(
                spot: spot,
                day_number: schedule_param[:day_number],
                time_zone: schedule_param[:time_zone],
                order_number: schedule_param[:order_number]
              )
            end
          end
        end
  
        render json: { 
          success: true,
          message: t('notices.spot.schedules_saved')
        }
      end
    rescue => e
      Rails.logger.error "Schedule save error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { 
        success: false,
        error: e.message 
      }, status: :unprocessable_entity
    end
  end

  def update_schedule
    @spot = Spot.find(params[:id])
    if @spot.update(schedule_params)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @spot = Spot.find(params[:id])
    if @spot.destroy
      head :ok
    else
      head :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Spot deletion error: #{e.message}"
    head :unprocessable_entity
  end

  def create_notification
    @travel = Travel.find(params[:travel_id])
    
    begin
      ActiveRecord::Base.transaction do
        @travel.travel_members.where(role: :guest).each do |member|
          # ここでNotificationを作成
          Notification.create!(
            recipient: member.user,
            notifiable: @travel,
            action: params[:notification_type]
          )
        end
        
        # 旅行を共有状態にマーク
        @travel.mark_as_shared!
        
        # 幹事はこの通知を受け取らないが、ここで共有状態を設定する
        TravelShare.create_or_find_by!(
          travel: @travel,
          notification_type: params[:notification_type]
        )
        
        render json: { 
          success: true, 
          message: t('notices.spot.notification_sent')
        }
      end
    rescue => e
      Rails.logger.error "Notification creation error: #{e.message}"
      render json: { 
        success: false, 
        error: e.message 
      }, status: :unprocessable_entity
    end
  end

  private

  def spot_params
    params.require(:spot).permit(:name, :category, :lat, :lng, :order_number)
  end

  def schedule_params
    params.require(:spot).permit(:day_number, :time_zone)
  end

  def set_travel
    @travel = Travel.find(params[:travel_id])
  end

  def check_member
    unless @travel.travel_members.exists?(user_id: current_user.id)
      redirect_to travels_path, alert: t('notices.travel.not_authorized')
    end
  end
end
