class Playable::MetadataProcessingJob < ApplicationJob
  queue_as :default

  def perform(media, parent_job_id: nil)
    unless media.is_a?(Movie) || media.is_a?(Episode)
      ApplicationLogger.warn("Unsupported playable type", location: media.class.name)
      return
    end

    Playable::MetadataService.call(media)
  ensure
    return unless parent_job_id

    JobProgress.async_item_completed!(parent_job_id, "#{media.class.name}:#{media.id}")
  end
end
