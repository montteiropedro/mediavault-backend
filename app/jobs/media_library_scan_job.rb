class MediaLibraryScanJob < ApplicationJob
  queue_as :default

  def perform(library_path = "/media/library")
    ScanMediaService.call(library_path)
  end
end
