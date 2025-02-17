# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick  # MiniMagickを追加

  storage :file

  # 画像のリサイズ設定
  process resize_to_fit: [800, 800]

  # サムネイルバージョンの作成
  version :thumb do
    process resize_to_fill: [150, 150]
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # アップロード可能な拡張子を設定
  def extension_allowlist
    %w(jpg jpeg gif png heic heif)
  end

  # アップロードサイズの制限
  def size_range
    1..10.megabytes
  end

  private

  def auto_orient
    manipulate! do |image|
      image.auto_orient
      image
    end
  end
end