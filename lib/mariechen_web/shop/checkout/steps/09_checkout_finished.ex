defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutFinished do
  @moduledoc false

  def process(conn, params) do
    vid = params.visit_id

    last_order_nr = Kandis.VisitorSession.get_value(vid, "last_order_nr")
    order = Kandis.Order.get_by_order_nr(last_order_nr)

    if(is_nil(order)) do
      raise "no valid order found "
    end

    conn
    |> Plug.Conn.merge_assigns(
      lang: params["lang"],
      order: order,
      orderhtml: Kandis.Order.get_orderhtml(order)
    )
  end
end
