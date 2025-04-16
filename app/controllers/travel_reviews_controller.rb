class TravelReviewsController < ApplicationController
  def create
    @travel = Travel.find(params[:travel_id])
    @review = @travel.travel_reviews.build(review_params)
    @review.user = current_user

    if @review.save
      # 幹事へ通知を送信
      Notification.create!(
        recipient: @travel.user,  # 幹事（travel.userが幹事）
        notifiable: @travel,
        action: "review_submitted"
      )

      redirect_to new_travel_spot_path(@travel), notice: "レビューを投稿しました"
    else
      redirect_to new_travel_spot_path(@travel), alert: "レビューの投稿に失敗しました"
    end
  end

  private

  def review_params
    params.require(:travel_review).permit(:content)
  end
end
