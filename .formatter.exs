[
  import_deps: [:ecto, :ecto_sql, :phoenix, :ash, :ash_authentication, :ash_postgres],
  subdirectories: ["priv/*/migrations"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/demo_seeds.exs",
    "priv/*/seeds.exs"
  ]
]
