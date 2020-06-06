defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutPickup do
  @moduledoc false
  @step "pickup"
  @pageview MariechenWeb.PageView
  use Kandis.Checkout.LiveViewStep
  use Phoenix.LiveView

  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    checkout_record = Kandis.Checkout.get_checkout_record(vid)
    Kandis.LiveUpdates.subscribe_live_view(vid)

    {:ok,
     assign(socket,
       vid: vid,
       lang: session["lang"],
       changeset: changeset_for_this_step(checkout_record, socket.assigns),
       checkout_record: checkout_record
     )}
  end

  @impl true
  def changeset_for_this_step(values, context) do
    _dummy = super(values, context)
    data = %{}
    types = %{pickup: :string, delivery_type: :string}

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types))
    |> Ecto.Changeset.validate_required([:pickup],
      message:
        MariechenWeb.MyHelpers.trans(
          context,
          "please choose a delivery-type",
          "bitte wählen Sie eine Zustellart aus"
        )
    )
  end

  @impl true
  def handle_event("save", msg = %{"step_data" => %{"pickup" => "yes"}}, socket) do
    msg =
      put_in(msg["step_data"]["delivery_type"], "pickup")
      |> IO.inspect(label: "mwuits-debug 2020-04-13_17:51 ADDED delivery_type 'pickup'")

    super_handle_event("save", msg, socket)
  end
end
