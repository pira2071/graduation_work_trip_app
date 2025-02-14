class SpotsController < ApplicationController
  include SchedulesHelper
  
  def new
    @travel = Travel.find(params[:travel_id])
    
    @spots = @travel.spots.includes(:schedule).order(:category, :order_number)
    
    @schedules = @travel.spots.includes(:schedule)
                       .where.not(schedules: { id: nil })
                       .order('schedules.day_number ASC, schedules.time_zone ASC, schedules.order_number ASC')
                       .to_a
  
    @total_days = (@travel.end_date - @travel.start_date).to_i + 1
  
    # JSONデータの準備を修正
    @spots_json = @spots.map do |spot|
      {
        id: spot.id,
        name: spot.name,
        category: spot.category,
        travel_id: @travel.id,
        schedule: spot.schedule ? {
          id: spot.schedule.id,
          day_number: spot.schedule.day_number,
          time_zone: spot.schedule.time_zone,
          order_number: spot.schedule.order_number
        } : nil
      }
    end
  
    # デバッグ出力
    Rails.logger.debug "Prepared spots JSON: #{@spots_json}"
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
          message: 'スポットを登録しました'
        }
      else
        raise ActiveRecord::Rollback
        render json: { 
          success: false, 
          errors: @spot.errors.full_messages,
          message: '登録に失敗しました'
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

  def cleanup
    @travel = Travel.find(params[:travel_id])
    @travel.spots.where(day_number: nil, time_zone: nil).destroy_all
    head :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def save_schedules
    @travel = Travel.find(params[:travel_id])
    schedules_params = params.require(:schedules).map do |schedule|
      schedule.permit(:spot_id, :day_number, :time_zone, :order_number)
    end
    deleted_spot_ids = params[:deleted_spot_ids] || []
  
    begin
      ActiveRecord::Base.transaction do
        # 既存のスケジュールを削除
        Schedule.where(spot_id: @travel.spot_ids).destroy_all
  
        # 削除予定のスポットを削除
        if deleted_spot_ids.any?
          @travel.spots.where(id: deleted_spot_ids).destroy_all
        end
  
        # 新しいスケジュールを作成
        schedules_params.each do |schedule_param|
          spot = @travel.spots.find(schedule_param[:spot_id])
          Schedule.create!(
            spot: spot,
            day_number: schedule_param[:day_number],
            time_zone: schedule_param[:time_zone],
            order_number: schedule_param[:order_number]
          )
        end
  
        render json: { 
          success: true,
          message: 'スケジュールを保存しました'
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

  private

  def spot_params
    params.require(:spot).permit(:name, :category, :lat, :lng, :order_number)
  end

  def schedule_params
    params.require(:spot).permit(:day_number, :time_zone)
  end
end
