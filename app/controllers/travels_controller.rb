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
    redirect_to travels_path, danger: t("notices.travel.not_found")
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

      redirect_to travels_path, success: t("notices.travel.created")
    else
      @friends = current_user.friends
      flash.now[:danger] = t("activerecord.errors.models.travel.creation_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # パラメータに応じてアクセス権限を分ける
    if params[:travel] && (params[:travel].keys & [ "title", "start_date", "end_date", "member_names" ]).any?
      # 基本情報の更新は幹事のみ可能
      @travel = current_user.organized_travels.find(params[:id])
    else
      # サムネイルの更新はメンバーも可能
      @travel = Travel.joins(:travel_members)
               .where(id: params[:id], travel_members: { user_id: current_user.id })
               .first

      # 該当するプランが見つからなかった場合
      unless @travel
        respond_to do |format|
          format.html { redirect_to travels_path, alert: t("notices.travel.not_authorized") }
          format.json { render json: { error: "アクセス権限がありません" }, status: :forbidden }
          format.js { head :forbidden }
        end
        return
      end
    end

    respond_to do |format|
      if @travel.update(travel_params)
        # AJAX (XHR) リクエストの場合
        format.js { head :ok }

        # 通常のリクエストの場合
        format.html do
          # フォーム経由での更新の場合、メンバーも更新
          if params[:member_ids].present?
            @travel.travel_members.where(role: :guest).destroy_all

            params[:member_ids].each do |member_id|
              user = User.find(member_id)
              @travel.travel_members.create(user: user, role: :guest)
            end
          end

          redirect_to @travel, success: t("notices.travel.updated")
        end

        # JSON形式のリクエストの場合
        format.json { render json: { success: true } }
      else
        @friends = current_user.friends
        format.html do
          flash.now[:danger] = t("activerecord.errors.models.travel.update_failed")
          render :edit, status: :unprocessable_entity
        end
        format.json { render json: { errors: @travel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @travel = current_user.organized_travels.find(params[:id])
    @travel.destroy!
    redirect_to travels_path, status: :see_other, success: t("notices.travel.destroyed")
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: t("notices.travel.not_found")
  end

  private

  def set_travel
    @travel = Travel.includes(:user, travel_members: :user)
                   .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to travels_path, danger: t("notices.travel.not_found")
  end

  def travel_params
    params.require(:travel).permit(:title, :start_date, :end_date, :thumbnail, :member_names)
  end
end
