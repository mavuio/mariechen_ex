defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutConfirm do
  @moduledoc false
  @step "confirm"

  def process(conn, %{"action" => "preconfirm"} = params) do
    vid = params.visit_id

    # ➜ Kandis.Check stock
    # If fail tuen redirevt
    conn =
      conn
      |> Kandis.Checkout.redirect_if_empty_cart(vid, params)

    if conn.halted do
      Plug.Conn.send_resp(conn, 503, "sorry, but your cart is empty")
    else
      order = create_order(vid, params)

      Plug.Conn.send_resp(conn, 200, "#{order.order_nr}")
      |> Plug.Conn.halt()
    end
  end

  def process(conn, params) do
    vid = params.visit_id

    # ➜ Kandis.Check stock
    # If fail tuen redirevt
    conn =
      conn
      |> Kandis.Checkout.redirect_if_empty_cart(vid, params)

    if conn.halted do
      conn
    else
      create_order(vid, params)

      conn
      |> Phoenix.Controller.redirect(to: Kandis.Checkout.get_next_step_link(params, @step))
      |> Plug.Conn.halt()
    end
  end

  def create_order(vid, params) do
    order = Kandis.Checkout.create_order_from_checkout(vid, params)

    Kandis.Order.cancel_orders_for_cart_id(order.orderdata.cart_id)

    Kandis.Order.set_state(order.id, "w4payment")
    |> Kandis.Order.decrement_stock_for_order()
  end
end
