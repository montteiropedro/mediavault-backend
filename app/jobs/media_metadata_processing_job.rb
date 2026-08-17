class MediaMetadataProcessingJob < ApplicationJob
  queue_as :default

  def perform(media_item_id)
    media_item = MediaItem.find_by(id: media_item_id)
    return unless media_item

    MediaMetadataService.call(media_item)
  end
end
