class Micropost < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  # 呼び出すときのデフォルトの並び順を指定できる
  # ちなみに、"->"はラムダ式。Procオブジェクトにcallメソッドを適用するとブロックの中身が実行される。
  default_scope -> { order(created_at: :desc) } # "::"じゃなくて": :"
  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
  validates :image,   content_type: { in: %w[image/jpeg image/gif image/png],
                      message: "must be a valid image format" },
                      size:         { less_than: 5.megabytes,
                      message: "should be less than 5MB" }

  # 表示用のリサイズ済み画像を返す
  def display_image
    image.variant(resize_to_limit: [500, 500])
  end
end
