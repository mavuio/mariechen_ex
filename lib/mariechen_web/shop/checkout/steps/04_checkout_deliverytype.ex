defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutDeliverytype do
  @moduledoc false
  @step "deliverytype"
  @pageview MariechenWeb.PageView

  use Kandis.Checkout.LiveViewStep
  use Phoenix.LiveView

  alias MariechenWeb.Shop.LocalCheckout

  use MariechenWeb.Live.AuthHelper
  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    checkout_record = Kandis.Checkout.get_checkout_record(vid)
    Kandis.LiveUpdates.subscribe_live_view(vid)

    delivery_country =
      if checkout_record.has_shipping_address == "yes" do
        checkout_record[:shipping_country] || checkout_record[:country]
      else
        checkout_record[:country]
      end

    deliverytypes = LocalCheckout.get_delivery_types(session["lang"], delivery_country)

    {:ok,
     assign(socket,
       vid: vid,
       lang: session["lang"],
       changeset: changeset_for_this_step(checkout_record, socket.assigns),
       checkout_record: checkout_record,
       delivery_types: deliverytypes
     )}
  end

  @impl true
  def changeset_for_this_step(values, context) do
    data = %{}
    types = %{delivery_type: :string}

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types))
    |> Ecto.Changeset.validate_required([:delivery_type],
      message:
        MariechenWeb.MyHelpers.trans(
          context,
          "please choose a delivery-type",
          "bitte wählen Sie eine Zustellart aus"
        )
    )
  end
end
