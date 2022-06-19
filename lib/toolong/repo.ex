defmodule Toolong.Repo do
  use Ecto.Repo,
    otp_app: :toolong,
    adapter: Ecto.Adapters.Postgres
end
