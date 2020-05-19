defmodule MariechenWeb.Shop.OrderRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    field(:order_nr, :string)
    field(:invoice_nr, :string)
    field(:state, :string, default: "created")
    field(:orderinfo, :map)
    field(:orderdata, :map)
    field(:history, :map)
    field(:user_id, :integer)
    field(:email, :string)
    field(:payment_type, :string)
    field(:delivery_type, :string)
    field(:shipping_country, :string)
    field(:total_price, :decimal)
    field(:cart_id, :string)
    timestamps()
  end

  use Accessible

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :order_nr,
      :invoice_nr,
      :state,
      :orderinfo,
      :orderdata,
      :history,
      :user_id,
      :email,
      :payment_type,
      :delivery_type,
      :shipping_country,
      :total_price,
      :cart_id
    ])
    |> unique_constraint(:invoice_nr)
    |> unique_constraint(:order_nr)
  end
end
