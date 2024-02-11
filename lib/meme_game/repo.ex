defmodule MemeGame.Repo do
  use Ecto.Repo,
    otp_app: :meme_game,
    adapter: Ecto.Adapters.Postgres
end
