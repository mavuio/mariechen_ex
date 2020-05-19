defmodule Mariechen.MixProject do
  use Mix.Project

  def project do
    [
      app: :mariechen,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(Mix.env())
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Mariechen.Application, []},
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
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:quick_alias, github: "werkzeugh/quick_alias", branch: "master"},
      {:myxql, "~> 0.3.0"},
      {:blankable, "~> 1.0"},
      {:memoize, "~> 1.2"},
      {:phoenix_live_view, "~> 0.9.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:accessible, "~> 0.2.1"},
      {:pow, "~> 1.0.18"},
      {:number, "~> 1.0"},
      # {:exi18n, "~> 0.8.0"},
      {:exi18n, github: "werkzeugh/exi18n", branch: "master"},
      {:yaml_elixir, "~> 1.3.0"},
      {:loggix, "~> 0.0.7"},
      {:countries, "~> 1.5"},
      {:csv, ">= 2.3.0"},
      {:bamboo, "~> 1.4"},
      {:httpoison, "~> 0.13 or ~> 1.0"},
      {:redirect, "~> 0.3.0"},
      {:tzdata, "~> 1.0.1"},
      {:quantum, "~> 2.3"},
      {:exsync, "~> 0.2", only: :dev}

      # {:kandis, path: "/www/kandis"},
    ]
  end

  defp deps(:prod) do
    deps() ++ [{:kandis, github: "werkzeugh/kandis", tag: "0.3.4", only: [:prod]}]
  end

  defp deps(_) do
    deps() ++ [{:kandis, path: "/www/kandis"}]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
