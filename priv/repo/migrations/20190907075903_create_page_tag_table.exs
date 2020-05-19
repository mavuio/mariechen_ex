defmodule Mariechen.Repo.Migrations.CreatePageTagTable do
  use Ecto.Migration

  def change do
    create table(:page_tag) do
      add(:page_id, :integer, null: false)
      add(:tag_id, :integer, null: false)
      timestamps()
    end

    create unique_index(:page_tag, [:page_id, :tag_id])
  end
end
