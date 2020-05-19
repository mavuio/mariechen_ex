defmodule MariechenWeb.BackendController do
  alias Kandis.Checkout
  alias MariechenWeb.Shop.LocalCart
  alias Kandis.Cart
  alias Kandis.Order
  use MariechenWeb, :controller

  plug :put_layout, "backend.html"

  def show_cart_data(conn, %{"sid" => sid} = _params) do
    session = %{"lang" => "de"}
    cart = Cart.get_augmented_cart_record(sid, session)
    checkout_record = Kandis.Checkout.get_checkout_record(sid)

    ordercart = Checkout.create_ordercart(cart, session["lang"])
    orderinfo = Checkout.create_orderinfo(checkout_record, sid)
    orderdata = Order.create_orderdata(ordercart, orderinfo)
    orderhtml = Order.create_orderhtml(orderdata, orderinfo)

    render(conn, "show_cart_data.html", %{sid: sid, orderhtml: orderhtml})
  end

  def list_orders(conn, params) do
    render(conn, "list_orders.html", %{orders: Order.get_orders(params)})
  end

  def list_carts(conn, params) do
    render(conn, "list_carts.html", %{carts: LocalCart.get_carts(params)})
  end

  def show_order(conn, %{"order_nr" => order_nr} = _params) do
    order = Order.get_by_order_nr(order_nr)
    orderhtml = Order.get_orderhtml(order)
    render(conn, "show_order.html", %{order: order, orderhtml: orderhtml})
  end

  def show_invoice(conn, %{"order_nr" => order_nr} = params) do
    with file when is_binary(file) <- Order.get_invoice_file(order_nr, params) do
      conn
      |> put_resp_content_type("application/pdf")
      |> Plug.Conn.send_file(200, file)
    else
      _ -> conn |> text("invoice-pdf not found")
    end
  end

  def show_invoice_html(conn, %{"order_nr" => order_nr} = _params) do
    order = Order.get_by_order_nr(order_nr)
    orderhtml = Order.get_orderhtml(order, "invoice")
    conn = conn |> put_layout("backend_empty.html")
    render(conn, "invoice_html.html", %{order: order, orderhtml: orderhtml})
  end

  def get_beuser_token(conn, %{"user_id" => user_id}) do
    token =
      case conn.host do
        "127.0.0.1" -> generate_beuser_token(user_id)
        _ -> "invalid_token"
      end

    json(conn, %{token: token, host: conn.host})
  end

  def generate_beuser_token(user_id \\ 1) do
    Phoenix.Token.sign(MariechenWeb.Endpoint, "user salt", user_id)
  end
end
