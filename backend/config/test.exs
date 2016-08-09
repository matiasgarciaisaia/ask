use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ask_backend, Ask.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :ask_backend, Ask.Repo,
  adapter: Ecto.Adapters.MySQL,
  username: "root",
  password: "",
  database: "ask_test",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox
