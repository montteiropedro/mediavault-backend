class Progress < ApplicationRecord
  belongs_to :user
  belongs_to :playable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:playable_type, :playable_id] }
end
