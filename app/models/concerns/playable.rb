module Playable
  extend ActiveSupport::Concern

  included do
    has_many :progresses, as: :playable, dependent: :destroy
  end

  def user_progress(user)
    progress = progresses.find_by(user:)
    progress&.seconds || 0
  end

  def self.find_playable(id, type:)
    case type&.downcase
    when "movie" then Movie.find(id)
    when "episode" then Episode.find(id)
    else raise "Playable type not defined"
    end
  end
end
