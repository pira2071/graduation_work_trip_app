class SchedulesController < ApplicationController
  before_action :set_travel

  def index
    @travel = Travel.find(params[:travel_id])
    @schedules = @travel.spots
                       .joins(:schedule)  # スケジュールが存在するものだけを取得
                       .includes(:schedule)  # N+1問題を防ぐ
                       .order('schedules.day_number ASC, schedules.time_zone ASC, schedules.order_number ASC')
    
    Rails.logger.debug "Schedules count: #{@schedules.count}"
    Rails.logger.debug "Schedules data: #{@schedules.to_json(include: :schedule)}"
  end

  def delete_spot
    @travel = Travel.find(params[:travel_id])
    spot = @travel.spots.find(params[:spot_id])
  
    ActiveRecord::Base.transaction do
      spot.schedule.destroy! if spot.schedule.present?
      spot.destroy!
    end

    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  rescue => e
    Rails.logger.error "Spot deletion error: #{e.message}"
    head :unprocessable_entity
  end

  def update_all
    begin
      ActiveRecord::Base.transaction do
        # 削除処理
        if params[:deletions].present?
          params[:deletions].each do |deletion|
            spot = @travel.spots.find(deletion[:spot_id])
            spot.schedule.destroy! if spot.schedule.present?
            spot.destroy!
          end
        end
  
        # スケジュール更新処理
        params[:schedules].each do |schedule_data|
          schedule = Schedule.find(schedule_data[:schedule_id])
          schedule.update!(
            day_number: schedule_data[:day_number],
            time_zone: schedule_data[:time_zone],
            order_number: schedule_data[:order_number]
          )
        end
      end
  
      render json: { success: true }
    rescue => e
      Rails.logger.error "Schedule update error: #{e.message}"
      render json: { error: '更新に失敗しました' }, status: :unprocessable_entity
    end
  end

  private

  def set_travel
    @travel = Travel.find(params[:travel_id])
  end
end
