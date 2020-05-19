defmodule Mariechen.Repo.Migrations.CreateSkuInOrders do
  use Ecto.Migration

  def change do
    create table(:sku_in_orders) do
      add :sku, :integer, null: false
      add :order_id, references(:orders)
      add :amount, :integer, null: false
      timestamps()
    end

    create unique_index(:sku_in_orders, [:sku, :order_id], name: :sku_in_oders_id_index)
  end
end
