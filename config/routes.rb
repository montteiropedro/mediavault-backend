require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do

      resources :library, only: [:index, :show] do
        get "scan", on: :collection
      end

      resources :playable, only: [] do
        post "/progresses", to: "progresses#create", on: :member
      end

      resources :streaming, only: [] do
        member do
          get "audio/:index", to: "streaming#audio"
          get "subtitle/:index",     to: "streaming#subtitle"
          get "hls/playlist.m3u8",   to: "streaming#hls_playlist"
          get "hls/:index.ts", to: "streaming#hls_segment"
        end
      end
    end
  end
end
