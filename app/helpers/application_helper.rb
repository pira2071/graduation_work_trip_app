module ApplicationHelper
  def default_meta_tags
    {
      site: 'TriPlanner',
      reverse: true,
      separator: '|',
      og: {
        type: 'website',
        site_name: 'TriPlanner',
        title: 'TriPlanner - 楽して旅の計画を',
        description: '旅行の計画をもっと簡単に。友達と共有しながら旅行計画を立てよう。',
        image: image_url('ogp.png'),
        url: 'http://tri-planner.com'
      },
      twitter: {
        card: 'summary_large_image'
      }
    }
  end

  # フラッシュタイプをBootstrapのalertクラスに変換するヘルパー
  def bootstrap_alert_class(flash_type)
    case flash_type.to_sym
    when :notice, :success
      'success'
    when :alert, :danger, :error
      'danger'
    when :warning
      'warning'
    when :info
      'info'
    else
      'info'  # デフォルトはinfo
    end
  end
  
  # ヘッダーを表示するページのみを判定するメソッド
  def show_header?
    # TOP画面のみヘッダーを表示
    controller_name == 'static_pages' && action_name == 'top'
  end

  # カテゴリに応じたバッジクラスを返すヘルパー
  def category_badge_class(category)
    case category.to_s
    when 'sightseeing'
      'bg-success'
    when 'restaurant'
      'bg-warning'
    when 'hotel'
      'bg-info'
    else
      'bg-secondary'
    end
  end

  # 時間帯によるカラークラスを返すヘルパー
  def time_zone_color(time_zone)
    case time_zone.to_s
    when 'morning'
      'bg-primary'
    when 'noon'
      'bg-warning'
    when 'night'
      'bg-dark'
    else
      'bg-light'
    end
  end

  # 時間帯のラベルを返すヘルパー
  def time_zone_label(time_zone)
    I18n.t("spots.time_zones.#{time_zone}", default: time_zone.to_s.humanize)
  end
end
