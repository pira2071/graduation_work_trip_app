class ThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  # 画像をアップロード時に適切な方向に回転
  process :auto_orient
  
  # 基本処理 - アスペクト比を無視して指定サイズにリサイズ
  process resize_to_fit: [1200, 1200]

  # カード一覧用のサムネイル - アスペクト比を無視
  version :card do
    process resize_to_fit: [400, 200]
  end

  # 詳細表示用 - アスペクト比を無視
  version :detail do
    process resize_to_fit: [800, 600] # 縦幅を400から600に増加
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
