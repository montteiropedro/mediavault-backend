require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/me" do
    context "when authenticated" do
      let(:user) { create(:user) }

      before do
        login(user)
        get "/api/v1/me"
      end

      it "returns http success" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the current user's serialized data" do
        json = JSON.parse(response.body)
        expect(json["display_name"]).to eq(user.display_name)
      end
    end

    context "when not authenticated" do
      it "returns http unauthorized without a cookie" do
        get "/api/v1/me"
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns http unauthorized with an invalid cookie" do
        post "/api/v1/session", params: { username: "invalid", token: "invalid" }
        get "/api/v1/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
