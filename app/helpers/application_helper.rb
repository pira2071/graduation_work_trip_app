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
  
  # ヘッダーを表示するページのみを判定するメソッド
  def show_header?
    # トップ画面のみヘッダーを表示する
    controller_name == 'static_pages' && action_name == 'top'
  end
end
