defmodule Mariechen.Repo do
  use Ecto.Repo,
    otp_app: :mariechen,
    adapter: Ecto.Adapters.MyXQL
end
