class TravelReviewsController < ApplicationController
    def create
      @travel = Travel.find(params[:travel_id])
      @review = @travel.travel_reviews.build(review_params)
      @review.user = current_user
  
      if @review.save
        redirect_to new_travel_spot_path(@travel), notice: 'レビューを投稿しました'
      else
        redirect_to new_travel_spot_path(@travel), alert: 'レビューの投稿に失敗しました'
      end
    end
  
    private
  
    def review_params
      params.require(:travel_review).permit(:content)
    end
  end
  