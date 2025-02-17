class PhotosController < ApplicationController
    before_action :set_travel
    
    def index
        @travel_days = (@travel.end_date - @travel.start_date).to_i + 1
        @photos_by_day = @travel.photos.order(created_at: :desc).group_by(&:day_number)
      end
  
    def day
      @day_number = params[:day_number].to_i
      @photos = @travel.photos.where(day_number: @day_number).order(created_at: :desc)
      render json: { photos: @photos.map { |p| { id: p.id, url: p.image.url } } }
    end
  
    def create
      @photo = @travel.photos.build(photo_params)
      @photo.user = current_user
    
      if @photo.save
        render json: {
          photo: {
            id: @photo.id,
            url: @photo.image.url
          }
        }, status: :created
      else
        render json: { errors: @photo.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Photo upload error: #{e.message}"
      render json: { error: "アップロードに失敗しました" }, status: :internal_server_error
    end
  
    def destroy
      @photo = @travel.photos.find(params[:id])
      
      if @photo.user_id == current_user.id
        if @photo.destroy
          head :no_content
        else
          render json: { error: '削除に失敗しました' }, status: :unprocessable_entity
        end
      else
        head :forbidden
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end
  
    private
  
    def set_travel
      @travel = Travel.find(params[:travel_id])
    end
  
    def photo_params
        params.require(:photo).permit(:image, :day_number)
    end
  end
