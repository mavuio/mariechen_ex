defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutShippingAddress do
  @moduledoc false
  @step "shipping_address"
  @pageview MariechenWeb.PageView

  use Kandis.Checkout.LiveViewStep

  alias MariechenWeb.MyHelpers

  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    checkout_record = Kandis.Checkout.get_checkout_record(vid)
    Kandis.LiveUpdates.subscribe_live_view(vid)

    {:ok,
     assign(socket,
       #  cart: cart,
       vid: vid,
       lang: session["lang"],
       changeset: changeset_for_this_step(checkout_record, session),
       checkout_record: checkout_record
     )}
  end

  @impl true
  def changeset_for_this_step(values, params) do
    data = %{}

    types = %{
      shipping_first_name: :string,
      shipping_last_name: :string,
      shipping_company: :string,
      shipping_email: :string,
      shipping_phone: :string,
      shipping_street: :string,
      shipping_city: :string,
      shipping_zip: :string,
      shipping_country: :string
    }

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types))
    |> Ecto.Changeset.validate_required([
      :shipping_first_name,
      :shipping_last_name,
      :shipping_street,
      :shipping_city,
      :shipping_zip,
      :shipping_country
    ])
    |> required_error_messages(MyHelpers.t(params, "msg.field_is_required"))
  end

  defp required_error_messages(changeset, new_error_message) do
    update_in(
      changeset.errors,
      &Enum.map(&1, fn
        {key, {"can't be blank", rules}} -> {key, {new_error_message, rules}}
        tuple -> tuple
      end)
    )
  end
end
