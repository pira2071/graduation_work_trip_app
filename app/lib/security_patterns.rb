module SecurityPatterns
  def self.dangerous_patterns
    [
      # ディレクトリトラバーサル
      /\.\.\//,

      # ファイルアクセス
      /\/etc\//,
      /\/bin\//,
      /\/boot\.ini/,
      /%SYSTEMROOT%/,
      /C:\\/,
      /file:\/\//,

      # コマンドインジェクション
      /\/bin\/cat/,
      /&&/,
      /\|/,
      />/,
      /;/,
      /\s+type\s+/,

      # XSS関連 - より具体的なパターンに変更
      /<script[\s\S]*?>[\s\S]*?<\/script>/i,  # スクリプトタグ
      /<iframe[\s\S]*?>[\s\S]*?<\/iframe>/i,  # iframeタグ
      /javascript:[\s\S]*?/i,   # javascript:プロトコル
      /data:text\/html[\s\S]*?/i, # data URIスキーム

      # イベントハンドラはより具体的に（addEventListener以外）
      /on(click|load|mouseover|mouseout|submit|focus|blur|change|keyup|keydown)=/i,

      # 悪意のある関数実行
      /eval\s*\(["'][\s\S]*?["']\)/i,  # eval関数（文字列リテラルを伴う場合）
      /exec\s*\(/i,
      /system\s*\(/i,
      /Function\s*\(["'][\s\S]*?["']\)/i,  # Function関数（文字列リテラルを伴う場合）

      # JavaScript関数は削除（正当な使用との競合を避けるため）
      # /alert\s*\(/i,
      # /confirm\s*\(/i,
      # /prompt\s*\(/i,

      # Cookieアクセス - より具体的に
      /document\.cookie\s*=/i,  # Cookieの設定のみ検出
      /document\.location\s*=/i, # location設定のみ検出

      # SQLインジェクション
      /--(.*?)=/,
      /union\s+select/i,
      /\bor\s+1\s*=\s*1\b/i,
      /\bselect\s+.*from\s+/i,
      /drop\s+table/i,
      /alter\s+table/i,
      /execute\s+immediate/i,
      /xp_cmdshell/i
    ]
  end

  def self.contains_dangerous_pattern?(str)
    return false unless str.is_a?(String)
    dangerous_patterns.any? { |pattern| str.match?(pattern) }
  end
end
