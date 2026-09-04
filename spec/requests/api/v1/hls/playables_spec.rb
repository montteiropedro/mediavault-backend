require "rails_helper"

RSpec.describe "Api::V1::Hls::Playables", type: :request do
  around do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = Pathname.new(tmp_dir)
      example.run
    end
  end

  let(:playable) { create(:movie) }

  before do
    user = create(:user)
    login(user)
  end

  before do
    allow(Library)
      .to receive(:find_playable)
      .with(playable.id.to_s, type: "movie")
      .and_return(playable)
  end

  describe "GET /hls/:type/:id/master.m3u8" do
    let(:playlist) { "#EXTM3U\n#EXT-X-VERSION:3\n" }

    before do
      allow(Hls::GenerateMasterService)
        .to receive(:call)
        .with(playable)
        .and_return(playlist)
    end

    it "returns the master playlist" do
      get "/api/v1/hls/movie/#{playable.id}/master.m3u8"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(playlist)
      expect(response.media_type).to eq("application/vnd.apple.mpegurl")
    end

    it "generates the playlist for the playable" do
      expect(Hls::GenerateMasterService)
        .to receive(:call)
        .with(playable)
        .and_return(playlist)

      get "/api/v1/hls/movie/#{playable.id}/master.m3u8"
    end
  end

  describe "GET /hls/:type/:id/video/playlist" do
    let(:cache) { instance_double(Hls::VideoCache) }
    let(:playlist) { "#EXTM3U\n#EXTINF:10,\n0.ts\n" }

    before do
      allow(Hls::VideoCache)
        .to receive(:new)
        .with(playable)
        .and_return(cache)

      allow(cache).to receive(:prepare!)

      allow(Hls::GeneratePlaylistService)
        .to receive(:call)
        .with(playable)
        .and_return(playlist)
    end

    it "prepares the video cache" do
      expect(cache).to receive(:prepare!)

      get "/api/v1/hls/movie/#{playable.id}/video/playlist"
    end

    it "returns the playlist" do
      get "/api/v1/hls/movie/#{playable.id}/video/playlist"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(playlist)
      expect(response.media_type).to eq("application/vnd.apple.mpegurl")
    end

    it "generates the playlist for the playable" do
      expect(Hls::GeneratePlaylistService)
        .to receive(:call)
        .with(playable)
        .and_return(playlist)

      get "/api/v1/hls/movie/#{playable.id}/video/playlist"
    end
  end

  describe "GET /hls/:type/:id/video/:segment_index" do
    let(:cache) { instance_double(Hls::VideoCache) }
    let(:path) { @tmp_dir.join("segment003.ts") }

    before do
      File.write(path, "fake video segment")

      allow(Hls::VideoCache)
        .to receive(:new)
        .with(playable)
        .and_return(cache)

      allow(cache)
        .to receive(:path)
        .with(3)
        .and_return(path)

      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(true)

      allow(Hls::SegmentLock)
        .to receive(:synchronize)
        .and_yield

      allow(FileUtils).to receive(:touch)
    end

    it "returns the segment" do
      get "/api/v1/hls/movie/#{playable.id}/video/3"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("video/mp2t")
    end

    it "does not generate an existing segment" do
      expect(Hls::GenerateVideoSegmentService)
        .not_to receive(:call)

      get "/api/v1/hls/movie/#{playable.id}/video/3"
    end

    it "generates the segment when it does not exist" do
      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(false)

      result = instance_double(
        "GenerateVideoSegmentResult",
        success: true
      )

      expect(Hls::GenerateVideoSegmentService)
        .to receive(:call)
        .with(playable, 3, path)
        .and_return(result)

      get "/api/v1/hls/movie/#{playable.id}/video/3"
    end

    it "uses the expected segment lock" do
      expect(Hls::SegmentLock)
        .to receive(:synchronize)
        .with(playable.id, "video", 3)
        .and_yield

      get "/api/v1/hls/movie/#{playable.id}/video/3"
    end

    it "returns 404 when generation fails" do
      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(false)

      result = instance_double(
        "GenerateVideoSegmentResult",
        success: false,
        stderr: "ffmpeg error"
      )

      allow(Hls::GenerateVideoSegmentService)
        .to receive(:call)
        .with(playable, 3, path)
        .and_return(result)

      expect(ApplicationLogger)
        .to receive(:error)
        .with(
          an_instance_of(RuntimeError),
          location: "Api::V1::Hls::PlayablesController"
        )

      expect(FileUtils).not_to receive(:touch)

      get "/api/v1/hls/movie/#{playable.id}/video/3"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /hls/:type/:id/audio/:track_index/playlist" do
    let(:cache) { instance_double(Hls::AudioCache) }
    let(:playlist) { "#EXTM3U\n#EXTINF:10,\n0.ts\n" }

    before do
      allow(Hls::AudioCache)
        .to receive(:new)
        .with(playable, 2)
        .and_return(cache)

      allow(cache).to receive(:prepare!)

      allow(Hls::GeneratePlaylistService)
        .to receive(:call)
        .with(playable)
        .and_return(playlist)
    end

    it "prepares the requested audio track" do
      expect(cache).to receive(:prepare!)

      get "/api/v1/hls/movie/#{playable.id}/audio/2/playlist"
    end

    it "returns the playlist" do
      get "/api/v1/hls/movie/#{playable.id}/audio/2/playlist"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(playlist)
      expect(response.media_type).to eq("application/vnd.apple.mpegurl")
    end
  end

  describe "GET /hls/:type/:id/audio/:track_index/:segment_index" do
    let(:cache) { instance_double(Hls::AudioCache) }
    let(:path) { @tmp_dir.join("segment003.ts") }

    before do
      File.write(path, "fake audio segment")

      allow(Hls::AudioCache)
        .to receive(:new)
        .with(playable, 2)
        .and_return(cache)

      allow(cache).to receive(:prepare!)

      allow(cache)
        .to receive(:path)
        .with(3)
        .and_return(path)

      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(true)

      allow(Hls::SegmentLock)
        .to receive(:synchronize)
        .and_yield

      allow(FileUtils).to receive(:touch)
    end

    it "prepares the audio cache" do
      expect(cache).to receive(:prepare!)

      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"
    end

    it "returns the segment" do
      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("video/mp2t")
    end

    it "does not generate an existing segment" do
      expect(Hls::GenerateAudioSegmentService)
        .not_to receive(:call)

      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"
    end

    it "generates the segment when it does not exist" do
      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(false)

      result = instance_double(
        "GenerateAudioSegmentResult",
        success: true
      )

      expect(Hls::GenerateAudioSegmentService)
        .to receive(:call)
        .with(playable, 2, 3, path)
        .and_return(result)

      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"
    end

    it "uses the expected segment lock" do
      expect(Hls::SegmentLock)
        .to receive(:synchronize)
        .with(playable.id, "audio-2", 3)
        .and_yield

      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"
    end

    it "returns 404 when generation fails" do
      allow(cache)
        .to receive(:exist?)
        .with(3)
        .and_return(false)

      result = instance_double(
        "GenerateAudioSegmentResult",
        success: false,
        stderr: "ffmpeg error"
      )

      allow(Hls::GenerateAudioSegmentService)
        .to receive(:call)
        .with(playable, 2, 3, path)
        .and_return(result)

      expect(ApplicationLogger)
        .to receive(:error)
        .with(
          an_instance_of(RuntimeError),
          location: "Api::V1::Hls::PlayablesController"
        )

      expect(FileUtils).not_to receive(:touch)

      get "/api/v1/hls/movie/#{playable.id}/audio/2/3"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /hls/:type/:id/subtitle/:track_index/playlist" do
    let(:cache) { instance_double(Hls::SubtitleCache) }
    let(:playlist) { "#EXTM3U\n..." }

    before do
      allow(Hls::SubtitleCache)
        .to receive(:new)
        .with(playable)
        .and_return(cache)

      allow(cache).to receive(:prepare!)

      allow(Hls::GenerateSubtitlePlaylistService)
        .to receive(:call)
        .with(playable, 2)
        .and_return(playlist)
    end

    it "prepares the subtitle cache" do
      expect(cache).to receive(:prepare!)

      get "/api/v1/hls/movie/#{playable.id}/subtitle/2/playlist"
    end

    it "returns the playlist" do
      get "/api/v1/hls/movie/#{playable.id}/subtitle/2/playlist"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(playlist)
      expect(response.media_type).to eq("application/vnd.apple.mpegurl")
    end
  end

  describe "GET /hls/:type/:id/subtitle/:track_index" do
    let(:cache) { instance_double(Hls::SubtitleCache) }
    let(:path) { @tmp_dir.join("002.ts") }

    before do
      File.write(path, "fake subtitle vtt")

      allow(Hls::SubtitleCache)
        .to receive(:new)
        .with(playable)
        .and_return(cache)

      allow(cache)
        .to receive(:path)
        .with(2)
        .and_return(path)

      allow(cache)
        .to receive(:exist?)
        .with(2)
        .and_return(true)

      allow(Hls::SegmentLock)
        .to receive(:synchronize)
        .and_yield

      allow(FileUtils).to receive(:touch)
    end

    it "returns the subtitle" do
      get "/api/v1/hls/movie/#{playable.id}/subtitle/2"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vtt")
    end

    it "does not generate an existing subtitle" do
      expect(Hls::GenerateSubtitleService)
        .not_to receive(:call)

      get "/api/v1/hls/movie/#{playable.id}/subtitle/2"
    end

    it "generates the subtitle when it does not exist" do
      allow(cache)
        .to receive(:exist?)
        .with(2)
        .and_return(false)

      result = instance_double(
        "GenerateSubtitleResult",
        success: true
      )

      expect(Hls::GenerateSubtitleService)
        .to receive(:call)
        .with(playable, 2, path)
        .and_return(result)

      get "/api/v1/hls/movie/#{playable.id}/subtitle/2"
    end

    it "uses the expected segment lock" do
      expect(Hls::SegmentLock)
        .to receive(:synchronize)
        .with(playable.id, "subtitle", 2)
        .and_yield

      get "/api/v1/hls/movie/#{playable.id}/subtitle/2"
    end

    it "returns 404 when generation fails" do
      allow(cache)
        .to receive(:exist?)
        .with(2)
        .and_return(false)

      result = instance_double(
        "GenerateSubtitleResult",
        success: false,
        stderr: "subtitle generation failed"
      )

      allow(Hls::GenerateSubtitleService)
        .to receive(:call)
        .with(playable, 2, path)
        .and_return(result)

      expect(ApplicationLogger)
        .to receive(:error)
        .with(
          an_instance_of(RuntimeError),
          location: "Api::V1::Hls::PlayablesController"
        )

      expect(FileUtils).not_to receive(:touch)

      get "/api/v1/hls/movie/#{playable.id}/subtitle/2"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "playable lookup" do
    it "returns 404 when the playable does not exist" do
      allow(Library)
        .to receive(:find_playable)
        .with("999", type: "movie")
        .and_raise(ActiveRecord::RecordNotFound)

      get "/api/v1/hls/movie/999/master.m3u8"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body)
        .to eq("error" => "Playable of type movie not found")
    end

    it "does not call the HLS service when the playable does not exist" do
      allow(Library)
        .to receive(:find_playable)
        .with("999", type: "movie")
        .and_raise(ActiveRecord::RecordNotFound)

      expect(Hls::GenerateMasterService).not_to receive(:call)

      get "/api/v1/hls/movie/999/master.m3u8"
    end
  end

  describe "playable type constraint" do
    it "does not route an unsupported type" do
      get "/api/v1/hls/not-a-playable/123/master.m3u8"

      expect(response).to have_http_status(:not_found)
    end

    Library.playable_types.each do |type|
      it "accepts #{type}" do
        playable = create(type.to_sym)

        allow(Library)
          .to receive(:find_playable)
          .with(playable.id.to_s, type: type)
          .and_return(playable)

        allow(Hls::GenerateMasterService)
          .to receive(:call)
          .with(playable)
          .and_return("#EXTM3U\n")

        get "/api/v1/hls/#{type}/#{playable.id}/master.m3u8"

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
