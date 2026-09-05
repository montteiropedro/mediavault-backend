module LibraryAttributes
  extend ActiveSupport::Concern

  included do
    attribute :type do |item|
      Library.type_for(item)
    end

    attribute :playable do |item|
      item.is_a?(Playable)
    end

    attribute :hls_url, if: -> (item, params) { item.is_a?(Playable) } do |item|
      "#{params[:request].base_url}/api/v1/hls/#{Library.type_for(item)}/#{item.id}/master.m3u8"
    end
  end
end
