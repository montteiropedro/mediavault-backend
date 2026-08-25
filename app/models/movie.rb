class Movie < ApplicationRecord
  include Playable

  has_one_attached :cover_art

  validates :title, presence: true
  validates :file_path, presence: true, uniqueness: true
end
