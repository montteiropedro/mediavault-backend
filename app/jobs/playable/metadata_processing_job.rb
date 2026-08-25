class Playable::MetadataProcessingJob < ApplicationJob
  queue_as :default

  def perform(media)
    unless media.is_a?(Movie) || media.is_a?(Episode)
      ApplicationLogger.warn("Unsupported playable type", location: media.class.name)
      return
    end

    Playable::MetadataService.call(media)
  end
end
