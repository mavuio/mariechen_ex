# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :mariechen,
  ecto_repos: [Mariechen.Repo]

# config :mariechen, MariechenWeb.Endpoint,
#   live_reload: [
#     url: "/"
#   ]
# Configures the endpoint
config :mariechen, MariechenWeb.Endpoint,
  url: [host: "localhost", path: "/ex"],
  secret_key_base: "ixriSBUo6Cy5lZR5cU9WuuysWk0NZAfoPkyqDjFDQcp/2MoOnz+Bki83mCVYSp/F",
  render_errors: [view: MariechenWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MariechenWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "XHSWWPbwpDZvz6RnNM7ZUMgmXBMOpKsU"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :exi18n,
  default_locale: "en",
  locales: ~w(en de),
  fallback: true,
  loader: :yml,
  loader_options: %{path: "priv/locales"},
  var_prefix: "%{",
  var_suffix: "}"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :logger,
  backends: [:console, {Loggix, :mix_application_log}],
  level: :debug

config :logger, :mix_application_log,
  path: "/www/mariechen_ex/logs/mix_application.log",
  format: "##_$level$levelpad | $date $time | $message\n\n",
  rotate: %{max_bytes: 10_485_760, keep: 40}

config :kandis,
  repo: Mariechen.Repo,
  pubsub: MariechenWeb.PubSub,
  local_checkout: MariechenWeb.Shop.LocalCheckout,
  local_cart: MariechenWeb.Shop.LocalCart,
  local_order: MariechenWeb.Shop.LocalOrder,
  server_view: MariechenWeb.ServerView,
  order_record: MariechenWeb.Shop.OrderRecord,
  translation_function: &MariechenWeb.MyHelpers.t/3,
  get_invoice_template_url: &MariechenWeb.MyHelpers.get_invoice_template_url/1,
  invoice_nr_prefix: "EBS",
  invoice_nr_testprefix: "EBT",
  steps_module_path: "MariechenWeb.Shop.Checkout.Steps",
  payments_module_path: "MariechenWeb.Shop.Payments"

config :mariechen, :api2pdf, base_url: "https://v2018.api2pdf.com"

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# config :stripy,
# secret_key: "sk_test_xxxxxxxxxxxxx", # required
# endpoint: "https://api.stripe.com/v1/", # optional
# version: "2017-06-05", # optional
# httpoison: [recv_timeout: 5000, timeout: 8000] # optional
