defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutPaymentReturn do
  @moduledoc false

  @step "payment_return"
  @pageview MariechenWeb.PageView

  use Kandis.Checkout.LiveViewStep

  @recheck_timeout 20_000

  @impl true
  def process(conn, %{"status" => "success", "order_nr" => order_nr} = params) do
    # live-view mode, wait for confirmation in callback

    order = Kandis.Order.get_current_order_for_vid(params.visit_id, params)

    cond do
      is_nil(order) ->
        raise "cannot find current order"

      order.order_nr != order_nr ->
        raise "something went wrong, paid-order mismatch:  #{order.order_nr} != #{order_nr}"

      true ->
        :ok
    end

    order
    |> get_next_link_for_order(params)
    |> case do
      # success or cancelled:
      link when is_binary(link) ->
        conn |> Phoenix.Controller.redirect(to: link) |> Plug.Conn.halt()

      # still waiting for callback:
      nil ->
        conn |> Plug.Conn.assign(:live_module, __MODULE__)
    end
  end

  @impl true
  def process(conn, params) do
    case params["status"] do
      nil ->
        Phoenix.Controller.put_flash(
          conn,
          :error,
          MariechenWeb.MyHelpers.trans(
            params,
            "an error occured in the payment-process ",
            "während des Zahlungs-Vorganges ist ein Fehler aufgetreten"
          )
        )

      "cancelled" ->
        Phoenix.Controller.put_flash(
          conn,
          :info,
          MariechenWeb.MyHelpers.trans(
            params,
            "the payment-process was aborted",
            "der Zahlungs-Vorgang wurde abgebrochen"
          )
        )
    end
    |> Phoenix.Controller.redirect(to: Kandis.Checkout.get_link_for_step(params, "review"))
    |> Plug.Conn.halt()
  end

  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    Kandis.LiveUpdates.subscribe_live_view(vid)

    order = Kandis.Order.get_current_order_for_vid(vid, session)

    if connected?(socket), do: Process.send_after(self(), :tick, @recheck_timeout)

    {:ok,
     assign(socket,
       vid: vid,
       cart_id: order.cart_id,
       lang: session["lang"],
       order: order
     )}
  end

  def handle_info({:visitor_session, [key, :updated], _new_data}, socket)
      when key in ["payment_log", "cart", "checkout", :all] do
    recheck_order(socket)
  end

  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @recheck_timeout)
    recheck_order(socket)
  end

  def recheck_order(socket) do
    cart_id =
      socket.assigns.cart_id
      |> IO.inspect(label: "mwuits-debug 2020-04-18_13:47 re-check cart_id")

    Kandis.Order.get_by_cart_id(cart_id)
    |> case do
      nil -> raise "cannot find valid order for cart_id #{cart_id}"
      order -> order
    end
    |> get_next_link_for_order(socket.assigns)
    |> case do
      nil -> {:noreply, socket}
      link -> {:noreply, socket |> redirect(to: link)}
    end
  end

  def get_next_link_for_order(order, context) do
    case order.state do
      "w4payment" ->
        nil

      state when state in ~w(w4payment cancelled created) ->
        Kandis.Checkout.get_link_for_step(context, "review")

      _ ->
        Kandis.Checkout.get_next_step_link(context, @step)
    end
  end
end
