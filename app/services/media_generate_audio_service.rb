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
    codec, channels, channel_layout = probe_audio_stream
    _stdout, stderr, status = Open3.capture3(*ffmpeg_command(codec, channels, channel_layout))

    Result.new(success: status.success?, stderr: stderr)
  end

  private

  def probe_audio_stream
    stdout, _stderr, status = Open3.capture3(
      'ffprobe',
      '-v', 'error',
      '-print_format', 'csv=p=0',
      '-select_streams', "a:#{@track_index}",
      '-show_entries', 'stream=codec_name,channels,channel_layout',
      @media_item.file_path.to_s
    )

    codec_name, channels, channel_layout = stdout.strip.split(',')
    channels = channels.to_i.clamp(1, 8)

    return [nil, channels, nil] unless status.success?

    [codec_name.presence, channels, channel_layout.presence]
  end

  def ffmpeg_command(codec, channels, channel_layout)
    audio_args =
      if BROWSER_COMPATIBLE_CODECS.include?(codec) && channel_layout_safe?(channels, channel_layout)
        ['-c:a', 'copy']
      else
        # A missing or unknown channel_layout usually indicates a PCE (Program Config Element) instead of the standard implicit channel signaling.
        # Browsers often fail to decode this, so we re-encode it, forcing a recognized standard layout.
        ['-c:a', 'aac', '-b:a', '192k', '-ac', channels.to_s, '-channel_layout', fallback_layout_for(channels)]
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

  # Mono/stereo almost always have a safe implicit layout, even without ffprobe reporting it;
  # for everything else, it requires channel_layout to be present.
  def channel_layout_safe?(channels, channel_layout)
    channels <= 2 || channel_layout.present?
  end

  def fallback_layout_for(channels)
    case channels.to_i
    when 1 then 'mono'
    when 2 then 'stereo'
    when 6 then '5.1'
    when 8 then '7.1'
    else 'stereo'
    end
  end
end
