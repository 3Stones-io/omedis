defmodule Omedis.Repo do
  use AshPostgres.Repo, otp_app: :omedis

  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext"]
  end
end
