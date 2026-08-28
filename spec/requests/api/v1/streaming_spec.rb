require "rails_helper"

RSpec.describe "Api::V1::Streaming", type: :request do
  describe "GET /api/v1/streaming/:id/subtitle/:index" do
    let(:user) { create(:user) }

    let(:playable) { create(:movie, title: "Test Movie", file_path: "/path/to/movie.mkv") }
    let(:track_index) { 123 }
    let(:cache) { instance_double(MediaSubtitleCache) }
    let(:cache_path) { "/tmp/fake-subtitle.vtt" }

    before do
      allow(MediaSubtitleCache).to receive(:new)
        .with(playable)
        .and_return(cache)

      allow(cache).to receive(:prepare!)
      allow(cache).to receive(:path)
        .with(track_index)
        .and_return(cache_path)

      allow_any_instance_of(Api::V1::StreamingController) .to receive(:send_file) do |controller, path, options|
        controller.render(
          plain: "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nfake subtitle",
          content_type: options[:type]
        )
      end

      login(user)
    end

    context "when the subtitle is not cached and the extraction succeeds" do
      before do
        allow(cache).to receive(:exist?)
          .with(track_index)
          .and_return(false)

        expect(MediaGenerateSubtitleService)
          .to receive(:call)
          .with(playable, track_index, cache_path)
          .and_return([
            "Subtitle extraction success",
            "",
            instance_double(Process::Status, success?: true)
          ])
      end

      it "extracts and returns the subtitle" do
        get "/api/v1/streaming/#{playable.id}/subtitle/#{track_index}", params: { type: "movie" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vtt")
        expect(response.body).to include("WEBVTT")
      end
    end

    context "when the subtitle is already cached" do
      before do
        allow(cache).to receive(:exist?)
          .with(track_index)
          .and_return(true)

        expect(MediaGenerateSubtitleService).not_to receive(:call)
      end

      it "returns the cached subtitle" do
        get "/api/v1/streaming/#{playable.id}/subtitle/#{track_index}", params: { type: "movie" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vtt")
        expect(response.body).to include("WEBVTT")
      end
    end

    context "when subtitle extraction fails" do
      before do
        allow(cache).to receive(:exist?)
          .with(track_index)
          .and_return(false)

        expect(MediaGenerateSubtitleService)
          .to receive(:call)
          .with(playable, track_index, cache_path)
          .and_return([
            "",
            "Subtitle extraction error",
            instance_double(Process::Status, success?: false, exitstatus: 1)
          ])

        expect(ApplicationLogger).to receive(:error)
      end

      it "returns 404 Not Found" do
        get "/api/v1/streaming/#{playable.id}/subtitle/#{track_index}", params: { type: "movie" }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
