class SpotsController < ApplicationController
  include SchedulesHelper
  
  def new
    @travel = Travel.find(params[:travel_id])
    @spots = @travel.spots.includes(:schedule)
    @schedules = @spots.select { |spot| spot.schedule.present? }
    @total_days = (@travel.end_date - @travel.start_date).to_i + 1
  
    # デバッグ用出力を追加
    Rails.logger.debug "==== Debug Info ===="
    Rails.logger.debug "Travel ID: #{@travel.id}"
    Rails.logger.debug "Spots count: #{@spots.count}"
    Rails.logger.debug "Scheduled spots count: #{@schedules.count}"
    @schedules.each do |spot|
      Rails.logger.debug "Spot: #{spot.name}, Schedule: #{spot.schedule.attributes}"
    end
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
  
    begin
      ActiveRecord::Base.transaction do
        # 既存のスケジュールを削除
        Schedule.where(spot_id: @travel.spot_ids).destroy_all
  
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
  
        # 更新後のデータを取得
        updated_spots = @travel.spots.includes(:schedule).map do |spot|
          {
            id: spot.id,
            name: spot.name,
            category: spot.category,
            lat: spot.lat,
            lng: spot.lng,
            travel_id: @travel.id,
            order_number: spot.order_number,
            schedule: spot.schedule&.as_json(
              only: [:id, :day_number, :time_zone, :order_number]
            )
          }
        end
  
        render json: { 
          success: true, 
          spots: updated_spots,
          message: 'スケジュールを保存しました'
        }
      end
    rescue => e
      Rails.logger.error "Schedule save error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { error: e.message }, status: :unprocessable_entity
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
