class Show < ApplicationRecord
  has_many :seasons, -> { order(:number) }, dependent: :destroy
  has_many :episodes, through: :seasons

  has_one_attached :cover_art

  validates :source_path, presence: true, uniqueness: true
end
