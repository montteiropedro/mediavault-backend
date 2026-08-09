class MediaGenerateSubtitleService
  def self.call(media_item, track_index, output_path)
    new(media_item, track_index, output_path).call
  end

  def initialize(media_item, track_index, output_path)
    @media_item = media_item
    @track_index = track_index
    @output_path = output_path
  end

  def call
    # FFmpeg command to extract and generate the specific track in .vtt
    Open3.capture3(
      'ffmpeg',
      '-y',
      '-v', 'error',
      '-i', @media_item.file_path,
      '-map', "0:s:#{@track_index}",
      '-f', 'webvtt',
      @output_path.to_s
    )
  end
end
