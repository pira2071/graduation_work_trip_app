# config/initializers/content_security_policy.rb
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :https, :data, 'https://cdnjs.cloudflare.com'
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, 'https://www.googletagmanager.com', 'https://cdnjs.cloudflare.com', 
                     'https://ga.jspm.io'
  policy.style_src   :self, :https, 'https://cdnjs.cloudflare.com'
  policy.connect_src :self, 'https://www.google-analytics.com'
end

# CSPを報告のみモードに設定（制限は行わない）
Rails.application.config.content_security_policy_report_only = true

# CSPの一時的な無効化（トラブルシューティングのみ)
# Rails.application.config.content_security_policy_nonce_directives = []
# Rails.application.config.content_security_policy_report_only = true