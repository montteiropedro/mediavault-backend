class User < ApplicationRecord
  before_validation :generate_token, on: :create

  has_many :progresses, dependent: :destroy

  validates :username, presence: true, uniqueness: true
  validates :token_digest, presence: true, uniqueness: true

  attr_reader :raw_token

  def display_name
    nickname.presence || username
  end

  def regenerate_token!
    @raw_token = SecureRandom.hex(32)
    update!(token_digest: Digest::SHA256.hexdigest(@raw_token))
  end

  def self.authenticate(username:, raw_token:)
    return nil if username.blank? || raw_token.blank?

    user = find_by(username: username)
    return nil unless user

    user.token_matches?(raw_token) ? user : nil
  end

  def self.authenticate_by_token(raw_token)
    return nil if raw_token.blank?

    given_digest = Digest::SHA256.hexdigest(raw_token)
    find_by(token_digest: given_digest)
  end

  def token_matches?(raw_token)
    given_digest = Digest::SHA256.hexdigest(raw_token)
    ActiveSupport::SecurityUtils.secure_compare(token_digest, given_digest)
  end

  private

  def generate_token
    return if token_digest.present?

    @raw_token = SecureRandom.hex(32)
    self.token_digest = Digest::SHA256.hexdigest(@raw_token)
  end
end
