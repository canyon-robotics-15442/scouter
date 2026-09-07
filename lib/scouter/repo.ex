defmodule Scouter.Repo do
  use Ecto.Repo,
    otp_app: :scouter,
    adapter: Ecto.Adapters.Postgres
end
