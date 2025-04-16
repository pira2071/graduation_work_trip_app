FactoryBot.define do
  factory :user do
    # sequence を使用して一意の名前を生成
    sequence(:name) { |n| "テストユーザー#{n}" }
    # または日本語名をランダムに生成する場合
    # sequence(:name) { |n| "#{%w[佐藤 鈴木 高橋 田中].sample} #{%w[太郎 花子 一郎 二郎].sample}#{n}" }

    # メールアドレスも一意にする
    sequence(:email) { |n| "user#{n}@example.com" }

    password { "password" }
    password_confirmation { "password" }
  end
end
