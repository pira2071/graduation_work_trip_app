module SchedulesHelper
  def time_zone_color(time_zone)
    case time_zone
    when 'morning' then 'bg-light-yellow'
    when 'noon' then 'bg-light-orange'
    when 'night' then 'bg-light-blue'
    end
  end

  def time_zone_label(time_zone)
    case time_zone
    when 'morning' then '朝'
    when 'noon' then '昼'
    when 'night' then '夜'
    end
  end

  def category_badge_class(category)
    case category
    when 'sightseeing' then 'bg-success'
    when 'restaurant' then 'bg-warning'
    when 'hotel' then 'bg-info'
    end
  end
end
