[
  import_deps: [
    :ash_archival,
    :ash_authentication,
    :ash_postgres,
    :ash,
    :ecto_sql,
    :ecto,
    :phoenix
  ],
  subdirectories: ["priv/*/migrations"],
  plugins: [Spark.Formatter, Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/demo_seeds.exs",
    "priv/*/seeds.exs"
  ]
]
