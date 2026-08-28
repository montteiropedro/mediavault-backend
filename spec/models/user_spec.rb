require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:progresses).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:user) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:token_digest) }
    it { is_expected.to validate_uniqueness_of(:username) }

    it "validates uniqueness of token_digest" do
      existing_user = create(:user)
      new_user = build(:user, token_digest: existing_user.token_digest)

      expect(new_user).not_to be_valid
      expect(new_user.errors[:token_digest]).to include("has already been taken")
    end
  end

  describe "#display_name" do
    it "returns nickname when present" do
      user = create(:user, username: "alice", nickname: "Ally")
      expect(user.display_name).to eq("Ally")
    end

    it "falls back to username when nickname is blank" do
      user = create(:user, username: "alice", nickname: "")
      expect(user.display_name).to eq("alice")
    end
  end

  describe ".authenticate" do
    let!(:user) { create(:user, username: "alice") }

    it "returns the user with correct username and raw_token" do
      expect(User.authenticate(username: "alice", raw_token: user.raw_token)).to eq(user)
    end

    it "returns nil with wrong token" do
      expect(User.authenticate(username: "alice", raw_token: "wrong")).to be_nil
    end

    it "returns nil with unknown username" do
      expect(User.authenticate(username: "ghost", raw_token: user.raw_token)).to be_nil
    end

    it "returns nil when username is blank" do
      expect(User.authenticate(username: "", raw_token: user.raw_token)).to be_nil
    end

    it "returns nil when raw_token is blank" do
      expect(User.authenticate(username: "alice", raw_token: "")).to be_nil
    end
  end

  describe ".authenticate_by_token" do
    let!(:user) { create(:user) }

    it "returns the user with correct raw_token" do
      expect(User.authenticate_by_token(user.raw_token)).to eq(user)
    end

    it "returns nil with wrong token" do
      expect(User.authenticate_by_token("wrong_token")).to be_nil
    end

    it "returns nil when raw_token is blank" do
      expect(User.authenticate_by_token("")).to be_nil
    end
  end

  describe "#regenerate_token!" do
    it "changes token_digest" do
      user = create(:user)
      expect { user.regenerate_token! }.to change(user, :token_digest)
    end

    it "sets a new raw_token" do
      user = create(:user)
      old_raw_token = user.raw_token
      user.regenerate_token!

      expect(user.raw_token).not_to eq(old_raw_token)
    end

    it "persists the new token_digest" do
      user = create(:user)
      user.regenerate_token!

      expect(user.reload.token_digest).to eq(Digest::SHA256.hexdigest(user.raw_token))
    end

    it "invalidates the old raw_token for authentication" do
      user = create(:user)
      old_raw_token = user.raw_token
      user.regenerate_token!

      expect(User.authenticate_by_token(old_raw_token)).to be_nil
    end

    it "allows authentication with the new raw_token" do
      user = create(:user)
      user.regenerate_token!

      expect(User.authenticate_by_token(user.raw_token)).to eq(user)
    end
  end

  describe "#generate_token" do
    it "sets token_digest before create" do
      user = build(:user, username: "alice")
      expect { user.save! }.to change(user, :token_digest).from(nil)
    end

    it "sets raw_token as an in-memory attribute" do
      user = create(:user, username: "alice")
      expect(user.raw_token).to be_present
    end

    it "stores token_digest as the SHA256 digest of raw_token" do
      user = create(:user, username: "alice")
      expect(user.token_digest).to eq(Digest::SHA256.hexdigest(user.raw_token))
    end

    it "never stores the raw token in token_digest" do
      user = create(:user, username: "alice")
      expect(user.token_digest).not_to eq(user.raw_token)
    end
  end
end
