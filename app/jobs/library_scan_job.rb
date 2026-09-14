class LibraryScanJob < ApplicationJob
  queue_as :default

  def perform
    progress = JobProgress.new(job_id)

    new_movies = progress.run("movies", weight: 10) { |progress| ScanMoviesService.call(progress:) }
    new_episodes = progress.run("shows", weight: 10) { |progress| ScanShowsService.call(progress:) }

    new_playables = new_movies + new_episodes

    if new_playables.empty?
      progress.complete!
    else
      progress.run_async("metadata", weight: 80, total: new_playables.size)
      new_playables.each { |playable| Playable::MetadataProcessingJob.perform_later(playable, parent_job_id: job_id) }
    end
  rescue => e
    progress&.fail!(e.message)
    raise
  end
end
