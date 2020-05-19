defmodule MariechenWeb.BagsController do
  use MariechenWeb, :controller

  alias Mariechen.Core.Bags

  def list(conn, params \\ %{}) do
    items = Bags.get_bags(params)

    json(conn, %{items: items})
  end

  def count(conn, params \\ %{}) do
    count = Bags.get_bag_count(params)
    json(conn, %{count: count})
  end

  def update_stock(conn, _params \\ %{}) do
    Mariechen.Core.Stock.write_stock_data()

    conn
    |> Plug.Conn.get_req_header("referer")
    |> case do
      [ref] ->
        conn
        |> redirect(external: ref)
        |> halt()

      _ ->
        text(conn, "stock updated")
    end
  end
end
