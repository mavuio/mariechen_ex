defmodule Mariechen.Repo.Migrations.CreateLocalOrderRecord do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :order_nr, :string, null: false
      add :invoice_nr, :string
      add :state, :string, default: "created", null: false
      add :orderinfo, :map
      add :orderdata, :map
      add :history, :map
      add :user_id, :integer
      add :email, :string
      add :payment_type, :string
      add :delivery_type, :string
      add :shipping_country, :string
      add :total_price, :decimal
      timestamps()
    end

    create unique_index(:orders, [:order_nr])
    create unique_index(:orders, [:invoice_nr])
  end
end
