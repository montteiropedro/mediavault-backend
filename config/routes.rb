Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      post "library/scan", to: "library#scan"

      resources :media_items, only: [:index] do
        get "subtitles/:index", action: :subtitles
        get "stream_audio/:index", action: :stream_audio
        get :stream, on: :member
        resources :media_progresses, only: [:create]
      end
    end
  end
end
