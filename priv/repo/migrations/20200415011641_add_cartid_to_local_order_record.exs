defmodule Mariechen.Repo.Migrations.AddCartidToLocalOrderRecord do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :cart_id, :string, null: true
    end

    create index(:orders, [:cart_id])
  end
end
