require "rails_helper"

RSpec.describe "Api::V1::Progresses", type: :request do
  describe "POST /api/v1/playable/:id/progresses" do
    let!(:user) { create(:user) }

    before { login(user) }

    context "when the playable is a Movie" do
      let(:movie) { create(:movie) }

      it "creates a new progress" do
        expect do
          post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 120 } }
        end.to change(Progress, :count).by(1)
      end

      it "associates the progress with the movie" do
        post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 60 } }

        expect(Progress.last.playable).to eq(movie)
      end

      it "returns 200 ok" do
        post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 120 } }

        expect(response).to have_http_status(:ok)
      end

      it "floors fractional seconds" do
        post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 120.9 } }

        expect(Progress.last.seconds).to eq(120)
      end

      it "sets last_watched_at to the current time" do
        freeze_time do
          post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 120 } }

          expect(Progress.last.last_watched_at).to eq(Time.current)
        end
      end
    end

    context "when the playable is an Episode" do
      let(:episode) { create(:episode) }

      it "creates a new progress" do
        expect do
          post "/api/v1/playable/#{episode.id}/progresses", params: { type: "episode", progress: { seconds: 60 } }
        end.to change(Progress, :count).by(1)
      end

      it "associates the progress with the episode" do
        post "/api/v1/playable/#{episode.id}/progresses", params: { type: "episode", progress: { seconds: 60 } }

        expect(Progress.last.playable).to eq(episode)
      end
    end

    context "when a progress already exists for the user and playable" do
      let(:movie) { create(:movie) }
      let!(:existing_progress) { create(:progress, user: user, playable: movie, seconds: 30) }

      it "updates the existing progress instead of creating a new one" do
        expect do
          post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 500 } }
        end.not_to change(Progress, :count)
      end

      it "updates the seconds on the existing record" do
        expect do
          post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: 500 } }
        end
          .to change { existing_progress.reload.seconds }
          .from(30)
          .to(500)
      end
    end

    context "when the playable does not exist" do
      it "returns 404 not found" do
        post "/api/v1/playable/00000000-0000-0000-0000-000000000000/progresses",
             params: { type: "movie", progress: { seconds: 120 } }

        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message" do
        post "/api/v1/playable/00000000-0000-0000-0000-000000000000/progresses",
             params: { type: "movie", progress: { seconds: 120 } }

        json = response.parsed_body
        expect(json["error"]).to eq("playable not found")
      end

      it "does not create a progress" do
        expect do
          post "/api/v1/playable/00000000-0000-0000-0000-000000000000/progresses",
               params: { type: "movie", progress: { seconds: 120 } }
        end.not_to change(Progress, :count)
      end
    end

    context "when the progress params are invalid" do
      let(:movie) { create(:movie) }

      before { allow_any_instance_of(Progress).to receive(:save).and_return(false) }

      it "returns 422 unprocessable_content" do
        post "/api/v1/playable/#{movie.id}/progresses", params: { type: "movie", progress: { seconds: nil } }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
