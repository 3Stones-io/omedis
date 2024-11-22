defmodule Mix.Tasks.CheckSnapshots do
  @moduledoc """
  Check if there are any resource snapshots to squash. Raise an error if there are.
  """

  use Mix.Task

  import ExUnit.CaptureIO

  @impl Mix.Task
  def run(_args) do
    output =
      capture_io(fn ->
        Mix.Task.run("ash_postgres.squash_snapshots", ["--check"])
      end)

    if String.trim(output) == "No snapshots to squash." do
      :ok
    else
      Mix.raise("""
      Snapshot check failed!\n
      Expected: "No snapshots to squash."
      Got: #{output}
      Please squash your snapshots using `mix ash_postgres.squash_snapshots`
      """)
    end
  end
end
