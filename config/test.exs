use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mariechen, MariechenWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mariechen, Mariechen.Repo,
  database: "mariechen",
  username: "webserver",
  password: "torm.avamanche.polx",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :mariechen, :config, local_url: "https://www.mariechen.com.test"
