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
  
    # 自分自身への申請をチェック
    if receiver.id == current_user.id
      flash[:error] = '自分自身に友達申請はできません'
      redirect_to friend_requests_path
      return
    end
  
    # 既存の友達関係をチェック
    if current_user.friends.include?(receiver)
      flash[:error] = 'すでに友達です'
      redirect_to friend_requests_path
      return
    end
  
    # 既存の申請をチェック（pendingとacceptedのみ）
    existing_request = Friendship.where(
      "(requester_id = ? AND receiver_id = ?) OR (requester_id = ? AND receiver_id = ?)",
      current_user.id, receiver.id, receiver.id, current_user.id
    ).where(status: ['pending', 'accepted']).first
  
    if existing_request
      flash[:error] = 'すでに友達申請が存在します'
      redirect_to friend_requests_path
      return
    end
  
    # 既存の拒否された申請があれば削除
    rejected_request = Friendship.where(
      "(requester_id = ? AND receiver_id = ?) OR (requester_id = ? AND receiver_id = ?)",
      current_user.id, receiver.id, receiver.id, current_user.id
    ).where(status: 'rejected').first
    
    rejected_request&.destroy
  
    @friendship = current_user.requested_friendships.build(
      receiver: receiver,
      status: 'pending'
    )
    
    if @friendship.save
      flash[:success] = 'フレンド申請を送信しました'
    else
      flash[:error] = '実行できませんでした。ユーザー名が正しいか、もう一度確認してください。'
    end
    
    redirect_to friend_requests_path
  end

  def accept
    @friendship = current_user.received_friendships.find(params[:id])
    
    if @friendship.update(status: 'accepted', accepted_at: Time.current)
      # 承認時の通知を作成
      Notification.create!(
        recipient: @friendship.requester,
        notifiable: @friendship,
        action: 'friend_request_accepted',
        read: false
      )
      redirect_to friendships_path, notice: 'フレンド申請を承認しました'
    else
      redirect_to friendships_path, alert: '承認に失敗しました'
    end
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
