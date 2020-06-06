defmodule MariechenWeb.Shop.Checkout.Steps.CheckoutAddress do
  @moduledoc false

  @step "address"
  @pageview MariechenWeb.PageView

  use Kandis.Checkout.LiveViewStep
  use Phoenix.LiveView

  import MariechenWeb.MyHelpers

  @impl true
  def mount(_params, session, socket) do
    vid = session["visit_id"]
    Kandis.LiveUpdates.subscribe_live_view(vid)

    checkout_record = Kandis.Checkout.get_checkout_record(vid)

    checkout_record =
      case checkout_record[:has_shipping_address] do
        nil -> checkout_record |> Map.put(:has_shipping_address, "no")
        _ -> checkout_record
      end

    {:ok,
     assign(socket,
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
      has_shipping_address: :string,
      first_name: :string,
      last_name: :string,
      company: :string,
      email: :string,
      phone: :string,
      street: :string,
      city: :string,
      zip: :string,
      country: :string
    }

    {data, types}
    |> Ecto.Changeset.cast(values, Map.keys(types))
    |> Ecto.Changeset.validate_required([
      :first_name,
      :last_name,
      :email,
      :street,
      :city,
      :zip,
      :country
    ])
    |> required_error_messages(t(params, "msg.field_is_required"))
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
