# MediaVault Backend

MediaVault is a self-hosted media library application. This repository contains the Rails API that indexes local movie and TV show files, tracks playback progress, and serves video, audio, and subtitle streams to the [MediaVault frontend](https://github.com/montteiropedro/mediavault-frontend).

## Features

- Scans local folders for movies and TV episodes.
- Reads media stream metadata with FFprobe.
- Serves HLS video, audio, and subtitle playlists and segments, generated with FFmpeg.
- Tracks user sessions and playback progress.
- Runs library scans and media processing in background jobs.

## Screenshots (🛠️ Work in progress...)

Screenshots or a short demo video help visitors understand the complete application before cloning it. The interface lives in the frontend repository, so add captures here once they are available, for example under `docs/images/`.

<!-- Add screenshots using: ![MediaVault library](docs/images/library.png) -->

## Tech stack

| Area                             | Technology                    |
| -------------------------------- | ----------------------------- |
| Language                         | Ruby 4.0.6                    |
| Framework                        | Ruby on Rails 8.1 API mode    |
| Database                         | PostgreSQL 15                 |
| Background jobs and queue        | Sidekiq with Redis            |
| Media inspection and transcoding | FFprobe and FFmpeg            |
| Containerized development        | Docker Compose                |
| Tests                            | RSpec                         |

## Requirements

- Docker (Docker Engine and the Docker Compose plugin).
- The [MediaVault frontend](https://github.com/montteiropedro/mediavault-frontend) repository, if you want to run the complete application.
- Local directories containing your media files.

The development Compose file builds the backend and Sidekiq worker from `Dockerfile.development`; PostgreSQL and Redis are provided as containers. The backend also joins an external Docker network named `mediavault`, shared with the frontend.

## Getting started

1. Clone this repository and enter its directory.
2. Create your local environment file:

   ```sh
   cp .env.example .env
   ```

3. Edit `.env` and set `DEFAULT_MOVIES_PATH` and `DEFAULT_SHOWS_PATH` to absolute paths on your machine. These host directories are mounted read-only into the containers at `/media/library/movies` and `/media/library/shows`.
4. Create the shared Docker network if it does not already exist:

   ```sh
   docker network create mediavault
   ```

5. Start the backend services:

   ```sh
   docker compose up --build
   ```

6. In another terminal, prepare the database and seed the initial user:

   ```sh
   docker compose exec backend bundle exec rails db:prepare
   docker compose exec backend bundle exec rails db:seed
   ```

The API is available at `http://localhost:3000` by default, and its health check is at `http://localhost:3000/up`. The seed command creates the `home` user, prints its generated token once, and enqueues an initial library scan. Keep that token private; use the username and token to sign in through the frontend.

To stop the services, run `docker compose down`. This preserves the PostgreSQL data volume. **Add `-v` only if you intend to delete that data**.

## Media folder layout

Movie files can be placed anywhere under the movies directory. TV shows should contain season directories; an optional category directory level is supported:

```text
movies/
|  Example Movie.mkv
shows/
|  One Example Show/
|  |  Season 1/
|  |  |  One Example Show S01E01.mkv
|  Drama/
|  |  Two Example Show/
|  |  |  S02/
|  |  |  |  Two Example Show S02E01.mp4
```

Supported video extensions are `.mp4`, `.mkv`, `.avi`, and `.mov`. Season folders should be named `Season 1`, `S1`, or another form starting with `season` or `s` followed by a number.

## Environment variables

`.env.example` documents the settings used by the development Compose setup. Defaults shown below are the values supplied by Compose when a setting is omitted, except where noted.

| Variable              | Default                          | Purpose                                                                                                        |
| --------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `PORT`                | `3000`                           | Host port mapped to the Rails API.                                                                             |
| `RAILS_MAX_THREADS`   | `10`                             | Rails thread count and database connection pool size.                                                          |
| `RAILS_HOSTS`         | —                                | Comma-separated additional hostnames allowed by Rails in development.                                          |
| `CORS_ORIGINS`        | —                                | Comma-separated additional frontend origins allowed by the API. `http://localhost:5173` is allowed by default. |
| `POSTGRES_USER`       | `postgres`                       | PostgreSQL username.                                                                                           |
| `POSTGRES_PASSWORD`   | `postgres`                       | PostgreSQL password; **change it outside local development**.                                                  |
| `POSTGRES_DB`         | `mediavault_backend_development` | PostgreSQL database created by Compose.                                                                        |
| `DB_HOST`             | `db`                             | PostgreSQL service hostname inside Compose.                                                                    |
| `DB_PORT`             | `5432`                           | Host port mapped to PostgreSQL.                                                                                |
| `REDIS_PORT`          | `6379`                           | Host port mapped to Redis; Compose builds the internal `REDIS_URL` from this value.                            |
| `SIDEKIQ_USERNAME`    | —                                | Username protecting the Sidekiq web UI at `/sidekiq`.                                                          |
| `SIDEKIQ_PASSWORD`    | —                                | Password protecting the Sidekiq web UI at `/sidekiq`. Set both credentials before exposing the UI.             |
| `DEFAULT_MOVIES_PATH` | — (required)                     | Absolute host path to the movies directory mounted read-only into the app and sidekiq.                         |
| `DEFAULT_SHOWS_PATH`  | — (required)                     | Absolute host path to the TV shows directory mounted read-only into the app and sidekiq.                       |

## API overview

All application endpoints are under `/api/v1`.

| Endpoint                                | Description                                        |
| --------------------------------------- | -------------------------------------------------- |
| `POST /api/v1/session`                  | Sign in and establish an API session.              |
| `DELETE /api/v1/session`                | Sign out.                                          |
| `GET /api/v1/me`                        | Get the current user.                              |
| `GET /api/v1/library`                   | List library items.                                |
| `GET /api/v1/library/:type/:id`         | Get a movie, show, season, or episode.             |
| `GET /api/v1/library/scan`              | Enqueue a library scan.                            |
| `POST /api/v1/playable/:id/progresses`  | Save playback progress.                            |
| `GET /api/v1/hls/:type/:id/master.m3u8` | Get an HLS master playlist for a movie or episode. |

Authentication accepts the session cookie or a bearer token in the `Authorization` header. Check `config/routes.rb` for the complete streaming and job-progress endpoints.

## Running specs

Run the test suite in the backend container:

```sh
docker compose exec backend bundle exec rspec
```

To run one spec file:

```sh
docker compose exec backend bundle exec rspec spec/requests/api/v1/sessions_spec.rb
```

## Project structure

- `app/controllers/api/v1/` — API endpoints.
- `app/jobs/` — asynchronous scans and media processing.
- `app/lib/` — shared helpers for job progress, media caching, and HLS segment handling.
- `app/services/` — library scanning, metadata extraction, and HLS generation.
- `app/models/` — users, library records, and playback progress.
- `spec/` — RSpec tests.
