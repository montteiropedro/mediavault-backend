class Season < ApplicationRecord
  belongs_to :show
  has_many :episodes, -> { order(:number) }, dependent: :destroy

  validates :show_id, uniqueness: { scope: :number }
  validates :number, presence: true
  validates :source_path, presence: true, uniqueness: true
end
