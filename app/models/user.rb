class User < ApplicationRecord
  has_many :progresses, dependent: :destroy

  validates :name, presence: true
end
