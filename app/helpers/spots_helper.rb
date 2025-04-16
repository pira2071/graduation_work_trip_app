module SpotsHelper
  def category_display(category)
    case category
    when "sightseeing" then "観光"
    when "restaurant" then "食事"
    when "hotel" then "宿泊"
    else category
    end
  end
end
