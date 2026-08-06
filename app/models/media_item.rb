class MediaItem < ApplicationRecord
  belongs_to :category, optional: true
  has_many :media_progresses, dependent: :destroy

  # Active Storage
  has_one_attached :cover_art

  enum :media_type, { video: 0, audio: 1, image: 2 }

  validates :title, presence: true
  validates :file_path, presence: true, uniqueness: true

  def user_progress(user = User.first)
    progress = media_progresses.find_by(user:)
    progress&.progress_seconds || 0
  end
end
