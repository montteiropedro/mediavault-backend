module Playable
  extend ActiveSupport::Concern

  included do
    has_many :progresses, as: :playable, dependent: :destroy

    def h264?
      codec_name.to_s.downcase == 'h264'
    end
  end

  def user_progress(user)
    progress = progresses.find_by(user:)
    progress&.seconds || 0
  end
end
