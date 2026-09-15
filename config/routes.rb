require "sidekiq/web"

Rails.application.routes.draw do
  library_types = Regexp.union(Library::TYPE_TO_MODEL.keys)
  playable_types = Regexp.union(Library.playable_types)

  mount Sidekiq::Web => "/sidekiq"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      resources :jobs, only: [] do
        resource :progress, only: :show, controller: "jobs/progress"
      end

      resource :session, only: [:create, :destroy]
      get "me", to: "users#me"

      get "library/:type/:id", to: "library#show", as: :library_item, constraints: { type: library_types }
      resources :library, only: [:index] do
        get "scan", on: :collection
      end

      resources :playable, only: [] do
        post "/progresses", to: "progresses#create", on: :member
      end

      namespace :hls do
        scope ":type/:id", constraints: { type: playable_types } do
          get "master.m3u8", to: "playables#hls_master"

          get "video/playlist", to: "playables#hls_video_playlist"
          get "video/:segment_index", to: "playables#hls_video_segment"
          get "audio/:track_index/playlist", to: "playables#hls_audio_playlist"
          get "audio/:track_index/:segment_index", to: "playables#hls_audio_segment"
          get "subtitle/:track_index/playlist", to: "playables#hls_subtitle_playlist"
          get "subtitle/:track_index", to: "playables#hls_subtitle"
        end
      end

      resources :streaming, only: [] do
        member do
          get "audio/:index", to: "streaming#audio"
          get "subtitle/:index",     to: "streaming#subtitle"
        end
      end
    end
  end
end
