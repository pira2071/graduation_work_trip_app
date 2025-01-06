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

  def reorder
    ActiveRecord::Base.transaction do
      params[:schedule_ids].each_with_index do |id, index|
        Schedule.find(id).update!(order_number: index + 1)
      end
    end
    head :ok
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  # app/controllers/schedules_controller.rb
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

  private

  def set_travel
    @travel = Travel.find(params[:travel_id])
  end
end
