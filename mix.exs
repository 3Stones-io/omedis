defmodule Omedis.MixProject do
  use Mix.Project

  def project do
    [
      app: :omedis,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :dev,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [
        check_code: :test,
        check_seeds: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
      gettext: [write_reference_line_numbers: false]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Omedis.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:igniter, "~> 0.3"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      # TODO bump on release to {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_view, "~> 1.0.0-rc.1", override: true},
      {:ash_authentication_phoenix, "~> 2.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:ash, "~> 3.0"},
      {:picosat_elixir, "~> 0.2"},
      {:finch, "~> 0.18.0"},
      {:ash_authentication, "~> 4.0"},
      {:ash_postgres, "~> 2.4"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:excoveralls, "~> 0.18.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.18"},
      {:bandit, "~> 1.5"},
      {:ash_phoenix, "~> 2.1.2"},
      {:slugify, "~> 1.3"},
      {:oban, "~> 2.17"},
      {:ash_archival, "~> 1.0.4"},
      {:ash_state_machine, "~> 0.2.7"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "seed.demo": ["run priv/repo/demo_seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": [
        "cmd --cd assets npm install",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": ["tailwind omedis", "esbuild omedis"],
      "assets.deploy": [
        "tailwind omedis --minify",
        "esbuild omedis --minify",
        "phx.digest"
      ],
      check_code: [
        "format --check-formatted",
        "credo --strict",
        "cmd make check-gettext",
        "ash_postgres.generate_migrations --check",
        "ash_postgres.squash_snapshots --check",
        "test --cover --warnings-as-errors"
      ],
      check_seeds: [
        "run priv/repo/seeds.exs",
        "run priv/repo/demo_seeds.exs",
        "run priv/repo/personas_seeds.exs"
      ]
    ]
  end
end
