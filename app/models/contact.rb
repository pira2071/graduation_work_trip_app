class Contact
  include ActiveModel::Model
  
  attr_accessor :name, :email, :subject, :message
  
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true, length: { maximum: 100 }
  validates :message, presence: true, length: { maximum: 2000 }

  # 危険な入力パターンのバリデーションを追加
  validate :no_dangerous_patterns
  
  private
  
  def no_dangerous_patterns
    attributes = {name: name, email: email, subject: subject, message: message}
    
    attributes.each do |attr_name, value|
      next unless value.is_a?(String)
      
      if SecurityPatterns.contains_dangerous_pattern?(value)
        errors.add(attr_name, "に不正な文字列が含まれています")
      end
    end
  end
  
  # 入力値をサニタイズするメソッド（必要に応じて使用）
  def sanitize_inputs
    require 'sanitize'
    
    self.name = Sanitize.fragment(name) if name
    self.subject = Sanitize.fragment(subject) if subject
    self.message = Sanitize.fragment(message) if message
    # emailはフォーマットバリデーションで対応するため除外
  end
end
