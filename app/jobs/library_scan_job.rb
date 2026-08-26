class LibraryScanJob < ApplicationJob
  queue_as :default

  def perform
    ScanMoviesService.call
    ScanShowsService.call
  end
end
