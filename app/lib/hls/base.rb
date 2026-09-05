module Hls::Base
  DEFAULT_BASE_DIR = Rails.root.join("tmp", "hls_cache").freeze
  SEGMENT_DURATION_IN_SECONDS = 6
end
