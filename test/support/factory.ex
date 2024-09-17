defmodule Omedis.Factory do
  @moduledoc """
  Factory module for creating test data.
  """
  use ExMachina.Ecto, repo: Omedis.Repo
  alias Omedis.Accounts.User

  def user_factory(attrs) do
    user = %User{}

    merge_attributes(user, attrs)
  end
end
