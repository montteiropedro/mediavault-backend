class MediaGenerateAudioService
  Result = Data.define(:success, :stderr)

  BROWSER_COMPATIBLE_CODECS = %w[aac mp3].freeze

  def self.call(media_item, track_index, output_path)
    new(media_item, track_index, output_path).call
  end

  def initialize(media_item, track_index, output_path)
    @media_item = media_item
    @track_index = track_index
    @output_path = output_path
  end

  def call
    codec = probe_audio_codec
    _stdout, stderr, status = Open3.capture3(*ffmpeg_command(codec))

    Result.new(success: status.success?, stderr: stderr)
  end

  private

  def probe_audio_codec
    stdout, _stderr, status = Open3.capture3(
      'ffprobe',
      '-v', 'error',
      "-print_format", "csv=p=0",
      '-select_streams', "a:#{@track_index}",
      '-show_entries', 'stream=codec_name',
      @media_item.file_path.to_s
    )

    return nil unless status.success?

    stdout.strip.presence
  end

  def ffmpeg_command(codec)
    audio_args =
      if BROWSER_COMPATIBLE_CODECS.include?(codec)
        ['-c:a', 'copy']
      else
        ['-c:a', 'aac', '-b:a', '192k']
      end

    [
      'ffmpeg',
      '-y',
      '-v', 'error',
      '-i', @media_item.file_path.to_s,
      '-map', "0:a:#{@track_index}",
      *audio_args,
      '-f', 'mp4',
      @output_path.to_s
    ]
  end
end
