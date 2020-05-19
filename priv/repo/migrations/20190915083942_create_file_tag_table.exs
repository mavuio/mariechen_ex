defmodule Mariechen.Repo.Migrations.CreateFileTagTable do
  use Ecto.Migration

  def change do
    create table(:file_tag) do
      add(:file_id, :integer, null: false)
      add(:tag_id, :integer, null: false)
      timestamps()
    end

    create unique_index(:file_tag, [:file_id, :tag_id])
  end
end
