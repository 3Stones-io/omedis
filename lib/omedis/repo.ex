defmodule Omedis.Repo do
  use Ecto.Repo,
    otp_app: :omedis,
    adapter: Ecto.Adapters.Postgres
end
