defmodule Mariechen.Core.Schemas.SkuInOrders do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias MariechenWeb.Shop.OrderRecord
  alias Mariechen.Core.Schemas.ProductVariant

  schema "sku_in_orders" do
    field(:amount, :integer)
    belongs_to :product_variant, ProductVariant, foreign_key: :sku
    belongs_to :order, OrderRecord, foreign_key: :order_id
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :sku,
      :order_id,
      :amount
    ])
    |> unique_constraint(:sku, name: :sku_in_oders_id_index)
  end
end
