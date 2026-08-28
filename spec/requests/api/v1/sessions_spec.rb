require 'rails_helper'

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/session" do
    let(:user) { create(:user) }

    context "with valid credentials" do
      before do
        post "/api/v1/session", params: { username: user.username, token: user.raw_token }
      end

      it "returns http success" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the user's serialized data" do
        json = JSON.parse(response.body)
        expect(json["display_name"]).to eq(user.display_name)
      end

      it "sets the api_token cookie" do
        expect(response.cookies["api_token"]).to be_present
      end

      it "allows a subsequent authenticated request" do
        get "/api/v1/me"
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an incorrect token" do
      before do
        post "/api/v1/session", params: { username: user.username, token: "invalid" }
      end

      it "returns http unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "does not set the api_token cookie" do
        expect(response.cookies["api_token"]).to be_nil
      end
    end

    context "with a nonexistent username" do
      it "returns http unauthorized" do
        post "/api/v1/session", params: { username: "invalid", token: "token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with blank params" do
      it "returns http unauthorized when username is blank" do
        post "/api/v1/session", params: { username: "", token: user.raw_token }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns http unauthorized when token is blank" do
        post "/api/v1/session", params: { username: user.username, token: "" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns http unauthorized when both are missing" do
        post "/api/v1/session"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it "does not require prior authentication" do
      post "/api/v1/session", params: { username: user.username, token: user.raw_token }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/session" do
    let(:user) { create(:user) }

    context "when authenticated" do
      before do
        post "/api/v1/session", params: { username: user.username, token: user.raw_token }
        delete "/api/v1/session"
      end

      it "returns http no_content" do
        expect(response).to have_http_status(:no_content)
      end

      it "clears the api_token cookie" do
        get "/api/v1/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when not authenticated" do
      it "returns http unauthorized" do
        delete "/api/v1/session"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
