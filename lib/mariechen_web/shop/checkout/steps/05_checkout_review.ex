defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutReview do
  @moduledoc false
  @step "review"
  @pageview MariechenWeb.PageView

  use Kandis.Checkout.LiveViewStep
  use Phoenix.LiveView

  use MariechenWeb.Live.AuthHelper
  import Kandis.KdHelpers, warn: false

  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    Kandis.LiveUpdates.subscribe_live_view(vid)

    checkout_record = Kandis.Checkout.get_checkout_record(vid)

    {orderdata, orderinfo, orderhtml} = Kandis.Checkout.preview_order(vid, _context = session)

    form_values = checkout_record

    socket =
      if checkout_record[:payment_type] == "creditcard" do
        assign(socket, payment_data_for_creditcard_payment(vid, session, orderdata, orderinfo))
      else
        socket
      end

    {:ok,
     assign(socket,
       #  cart: cart,
       vid: vid,
       lang: session["lang"],
       changeset: changeset_for_this_step(form_values, socket.assigns),
       checkout_record: checkout_record,
       orderhtml: orderhtml,
       orderinfo: orderinfo,
       orderdata: orderdata
     )}
  end

  @impl true
  def changeset_for_this_step(values, context) do
    data = %{}
    types = %{payment_type: :string}

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types))
    |> Ecto.Changeset.validate_required([:payment_type],
      message:
        MariechenWeb.MyHelpers.trans(
          context,
          "please choose a payment-type",
          "bitte wählen Sie eine Zahlungsart aus"
        )
    )
  end

  def handle_event(
        "validate" = event,
        msg = %{"step_data" => %{"payment_type" => payment_type}},
        socket
      ) do
    # save payment-type immediately:
    Kandis.Checkout.update(socket.assigns.vid, %{payment_type: payment_type})

    {payment_type, socket.assigns[:stripe_pk]}
    |> IO.inspect(label: "mwuits-debug 2020-04-14_17:17  -----------------------------------")

    if payment_type == "creditcard" and is_nil(socket.assigns[:stripe_pk]) do
      reload_current_page(socket) |> IO.inspect(label: "RELOAD!! ")
    else
      super_handle_event(event, msg, socket)
    end
  end

  # def handle_event("save", msg, socket) do
  #   incoming_data =
  #     case msg do
  #       %{"step_data" => incoming_data} -> incoming_data
  #       _ -> %{}
  #     end

  #   incoming_data
  #   |> changeset_for_this_step(socket.assigns)
  #   |> Ecto.Changeset.apply_action(:insert)
  #   |> case do
  #     {:ok, clean_incoming_data} ->
  #       checkout_record = Kandis.Checkout.update(socket.assigns.vid, clean_incoming_data)

  #       case checkout_record[:payment_type] do
  #         "creditcard" ->
  #           {:noreply, socket}

  #         _ ->
  #           {:noreply,
  #            socket
  #            |> redirect(to: Kandis.Checkout.get_next_step_link(socket.assigns, "review"))}
  #       end

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end

  def payment_data_for_creditcard_payment(vid, context, orderdata, orderinfo)
      when is_binary(vid) and is_map(orderdata) and is_map(orderinfo) do
    payment_attempt =
      Kandis.Payment.get_or_create_payment_attempt_for_provider(
        "stripe",
        "n/a",
        orderdata,
        orderinfo
      )

    payment_attempt |> IO.inspect(label: "mwuits-debug 2020-04-21_00:33 PAYMENT ATTEMPT CRERATED")
    head_addons = []
    head_addons = head_addons ++ ["<script src=\"https://js.stripe.com/v3/\"></script>"]

    {stripe_msg, stripe_client_secret} =
      case payment_attempt do
        %{data: %{"client_secret" => val}} ->
          {nil, val}

        %{data: %{"error" => %{"code" => "payment_intent_unexpected_state"}}} ->
          {"the current order might already have been paid !", nil}

        _ ->
          {"payment-method not available at the moment", nil}
      end

    preconfirm_url =
      MariechenWeb.Router.Helpers.checkout_step_path(
        MariechenWeb.Endpoint,
        :step,
        context["lang"],
        "confirm"
      ) <> "?action=preconfirm"

    payment_step_url =
      MariechenWeb.Router.Helpers.checkout_step_path(
        MariechenWeb.Endpoint,
        :step,
        context["lang"],
        "payment"
      )

    [
      payment_attempt: payment_attempt,
      stripe_pk: Application.fetch_env!(:stripy, :public_key),
      stripe_client_secret: stripe_client_secret,
      stripe_msg: stripe_msg,
      head_addons: head_addons,
      stripe_preconfirm_url: preconfirm_url,
      stripe_payment_step_url: payment_step_url
    ]
  end
end
