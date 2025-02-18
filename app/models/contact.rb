class Contact
  include ActiveModel::Model
  
  attr_accessor :name, :email, :subject, :message
  
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true, length: { maximum: 100 }
  validates :message, presence: true, length: { maximum: 2000 }
end
