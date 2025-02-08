class FriendshipsController < ApplicationController
  before_action :require_login
  before_action :set_friendship, only: [:accept, :reject]

  def index
    @friends = current_user.friends
    @pending_requests = current_user.pending_friend_requests
  end

  def requests
    @pending_requests = current_user.pending_friend_requests
  end

  def create
    receiver = User.find_by(name: params[:name])
    
    if receiver.nil?
      flash[:error] = '実行できませんでした。ユーザー名が正しいか、もう一度確認してください。'
      redirect_to friend_requests_path
      return
    end

    @friendship = current_user.requested_friendships.build(receiver: receiver)
    
    if @friendship.save
      flash[:success] = 'フレンド申請を送信しました'
    else
      flash[:error] = '実行できませんでした。ユーザー名が正しいか、もう一度確認してください。'
    end
    
    redirect_to friend_requests_path
  end

  def accept
    @friendship.update(status: 'accepted', accepted_at: Time.current)
    redirect_to friendships_path, notice: 'フレンド申請を承認しました'
  end

  def reject
    @friendship.update(status: 'rejected', rejected_at: Time.current)
    redirect_to friendships_path, notice: 'フレンド申請を拒否しました'
  end

  private

  def set_friendship
    @friendship = current_user.received_friendships.find(params[:id])
  end
end
