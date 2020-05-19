defmodule ElixirWeb.Plugs.RequireBeUser do
  @moduledoc "require valid beuser cookie"
  @behaviour Plug
  import Phoenix.Controller, only: [redirect: 2, current_path: 1]
  import Plug.Conn, only: [halt: 1]
  import Kandis.KdHelpers

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    conn.params["token"]
    |> if_empty(conn.cookies["ex_betoken"])
    |> valid_token?()
    |> case do
      false ->
        back_url = MariechenWeb.Router.Helpers.static_path(conn, current_path(conn))
        conn |> redirect(to: "/BE/?" <> URI.encode_query(BackURL: back_url)) |> halt()

      _ ->
        conn
    end
  end

  def valid_token?(nil), do: false

  def valid_token?(token) do
    Phoenix.Token.verify(MariechenWeb.Endpoint, "user salt", token, max_age: 86400)
    # |> IO.inspect(label: "mwuits-debug 2020-03-28_16:30 VERIFY")
    |> case do
      {:ok, _userid} -> true
      _ -> false
    end
  end
end
