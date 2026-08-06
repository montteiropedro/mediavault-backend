class User < ApplicationRecord
  has_many :media_progresses, dependent: :destroy
  has_many :collections, dependent: :destroy

  validates :name, presence: true
end
