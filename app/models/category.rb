class Category < ApplicationRecord
  has_many :media_items, dependent: :nullify
  validates :name, presence: true, uniqueness: true
end
