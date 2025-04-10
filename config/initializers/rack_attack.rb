class Rack::Attack
  # キャッシュストアの設定
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  
  # 同一IPからのリクエスト回数制限（全般）
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end
  
  # お問い合わせフォームに特化した制限
  throttle('contacts/ip', limit: 3, period: 30.minutes) do |req|
    req.ip if req.path == '/contact_us' && req.post?
  end
  
  # ログイン試行の制限
  throttle('logins/ip', limit: 30, period: 20.minutes) do |req|
    req.ip if req.path == '/login' && req.post?
  end
  
  # 同一IPからの連続POST制限
  throttle('post/ip', limit: 100, period: 5.minutes) do |req|
    req.ip if req.post?
  end
  
  # 複数の不正パラメータを含むリクエストをIPアドレスでブロック
  blocklist('malicious_request/ip') do |req|
    # 7分間に3回以上悪意のあるリクエストを送ってきたIPをブロック
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 3, findtime: 7.minutes, bantime: 1.hour) do
      # 不正パラメータが含まれているかチェック
      has_malicious_params = false
      
      if req.params.is_a?(Hash)
        req.params.each do |_, value|
          if value.is_a?(String) && SecurityPatterns.contains_dangerous_pattern?(value)
            has_malicious_params = true
            break
          end
        end
      end
      
      has_malicious_params
    end
  end
  
  # ブラックリスト（必要に応じて特定のIPをブロック）
  # blocklist('block bad ips') do |req|
  #   ['1.2.3.4', '5.6.7.8'].include?(req.ip)
  # end
  
  # 攻撃検出時のログ記録
  self.throttled_response_retry_after_header = true
  
  # 制限に達した場合のレスポンス
  self.throttled_response = ->(env) {
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {'Content-Type' => 'application/json', 'Retry-After' => retry_after.to_s},
      [{ error: "リクエスト回数の制限を超えました。しばらく経ってから再度お試しください。" }.to_json]
    ]
  }
end
