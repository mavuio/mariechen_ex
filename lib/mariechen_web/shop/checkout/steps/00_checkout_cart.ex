defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutCart do
  @moduledoc false
  use Phoenix.LiveView

  # alias Kandis.VisitorSession
  alias Kandis.LiveUpdates
  alias Kandis.Cart
  alias Kandis.Checkout, warn: false
  alias MariechenWeb.Shop.Promocodes

  import Kandis.KdHelpers
  import MariechenWeb.MyHelpers

  use MariechenWeb.Live.AuthHelper

  def process(conn, _params) do
    conn
    |> Plug.Conn.assign(:live_module, __MODULE__)
  end

  def render(assigns) do
    Phoenix.View.render(MariechenWeb.PageView, "checkout_cart.html", assigns)
  end

  def mount(_params, session, socket) do
    vid = session["visit_id"]

    cart = Cart.get_augmented_cart_record(vid, session)

    LiveUpdates.subscribe_live_view(vid)

    {:ok, assign(socket, cart: cart, vid: vid, lang: session["lang"])}
  end

  def handle_event("remove_item", %{"sku" => sku}, socket) do
    Cart.remove_item(socket.assigns[:vid], sku)
    {:noreply, socket}
  end

  def handle_event("remove_promocode", %{"promocode" => promocode}, socket) do
    Cart.remove_promocode(socket.assigns[:vid], promocode)
    {:noreply, socket}
  end

  def handle_event("change_quantity", %{"sku" => sku, "mode" => mode}, socket) do
    Cart.change_quantity(socket.assigns[:vid], sku, 1, mode)
    {:noreply, socket}
  end

  def handle_event("save_promocode", %{"promocode" => promocode}, socket) do
    code =
      promocode
      |> if_nil("")
      |> String.trim()
      |> String.upcase()
      |> IO.inspect(label: "mwuits-debug 2020-03-24_11:34 CODE")

    promo_msg =
      Promocodes.promocode_is_valid?(code, socket.assigns.cart)
      |> case do
        true ->
          Cart.add_promocode(socket.assigns[:vid], code)

          trans(
            socket.assigns,
            "✔ Promo-Code '#{code}' was applied",
            "✔ der Promo-Code '#{code}' wurde angewendet"
          )

        false ->
          trans(
            socket.assigns,
            "✖ sorry, but the Promo-Code '#{code}' is not valid",
            "✖ der Promo-Code '#{code}' ist leider nicht gültig"
          )
      end

    {:noreply, assign(socket, promo_msg: promo_msg)}
  end

  def handle_info({:visitor_session, [_, :updated], new_cart}, socket) do
    {:noreply, assign(socket, cart: Cart.get_augmented_cart_record(new_cart, socket.assigns))}
  end

  def handle_info({:cart, :limit_reached, max}, socket) do
    {:noreply, socket |> put_flash(:error, "Limit #{max} reached ")}
  end

  def handle_info(msg, socket) do
    msg |> IO.inspect(label: "UNKNOWN MSG received by cart")
    {:noreply, socket}
  end
end
