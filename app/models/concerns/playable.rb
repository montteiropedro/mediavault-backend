module Playable
  extend ActiveSupport::Concern

  included do
    has_many :progresses, as: :playable, dependent: :destroy
  end

  def user_progress(user)
    progress = progresses.find_by(user:)
    progress&.seconds || 0
  end
end
