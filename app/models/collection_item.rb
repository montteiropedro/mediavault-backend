class CollectionItem < ApplicationRecord
  belongs_to :collection
  belongs_to :media_item

  validates :media_item_id, uniqueness: { scope: :collection_id }
end
