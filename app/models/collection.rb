class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_items, dependent: :destroy
  has_many :media_items, through: :collection_items

  validates :name, presence: true
end
