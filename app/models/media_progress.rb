class MediaProgress < ApplicationRecord
  belongs_to :user
  belongs_to :media_item

  validates :user_id, uniqueness: { scope: :media_item_id }

  def completed?
    return false if media_item.duration.blank? || media_item.duration.zero?

    (progress_seconds.to_f / media_item.duration) >= 0.95
  end
end
