class Episode < ApplicationRecord
  include Playable

  belongs_to :season

  has_one_attached :thumbnail

  validates :season_id, uniqueness: { scope: :number }
  validates :file_path, presence: true, uniqueness: true
end
