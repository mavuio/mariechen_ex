defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutPayment do
  @moduledoc false

  def process(conn, params) do
    vid = params.visit_id
    order = Kandis.Order.get_current_order_for_vid(vid)

    conn = Kandis.Checkout.redirect_if_invalid_order(conn, order, params)

    if conn.halted do
      conn
    else
      payment_attempt =
        case order.orderinfo.payment_type do
          "sofort" ->
            Kandis.Payment.create_and_add_payment_attempt_for_provider(
              "sofort",
              order.order_nr,
              order.orderdata,
              order.orderinfo
            )

          _ ->
            nil
        end

      case order.orderinfo.payment_type do
        "creditcard" ->
          # stripe payment has already started, wait for return
          conn
          |> Phoenix.Controller.redirect(
            to:
              Kandis.Checkout.get_link_for_step(params, "payment_return") <>
                "?status=success&order_nr=#{order.order_nr}"
          )
          |> Plug.Conn.halt()

        _ ->
          conn
          |> Plug.Conn.merge_assigns(
            lang: params["lang"],
            order: order,
            payment_attempt: payment_attempt
          )
      end
    end
  end
end
