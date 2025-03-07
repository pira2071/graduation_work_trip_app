module TravelsHelper
  def can_edit_thumbnail?(travel)
    travel.travel_members.exists?(user_id: current_user.id)
  end
  
  def can_edit_travel?(travel)
    travel.user_id == current_user.id
  end
end
