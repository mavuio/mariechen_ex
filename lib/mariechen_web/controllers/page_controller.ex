defmodule MariechenWeb.PageController do
  alias Kandis.Cart
  use MariechenWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def cart(conn, _params) do
    render(conn, "cart.html")
  end

  def add_to_cart(conn, %{"sku" => sku} = _params) do
    res = Cart.add_item(conn.assigns.visit_id, sku)
    json(conn, %{payload: res})
  end

  def get_cart_count(conn, _params) do
    res = Cart.get_cart_count(conn.assigns.visit_id)
    json(conn, %{payload: res})
  end
end
