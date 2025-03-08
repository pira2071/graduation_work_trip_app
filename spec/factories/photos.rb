# spec/factories/photos.rb
FactoryBot.define do
  factory :photo do
    association :travel
    association :user
    day_number { 1 }
    
    # 画像をモックする
    transient do
      skip_image { false }
    end
    
    after(:build) do |photo, evaluator|
      unless evaluator.skip_image
        # 画像ファイルの代わりにアップローダーの振る舞いだけをモック
        image_mock = double('image')
        allow(image_mock).to receive(:url).and_return('/uploads/test-image.png')
        allow(image_mock).to receive(:thumb).and_return(double('thumb', url: '/uploads/thumb-test-image.png'))
        
        # Photoオブジェクトがimage,image.urlなどを参照できるようにする
        allow(photo).to receive(:image).and_return(image_mock)
      end
    end
  end
end
