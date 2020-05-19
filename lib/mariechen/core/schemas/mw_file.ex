defmodule Mariechen.Core.Schemas.MwFile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "MwFile" do
    field(:filename, :string, source: :filename)
    field(:parent_id, :integer, source: :parentid)
    field(:sort, :integer)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(
      params,
      [
        :filename,
        :parent_id
      ]
    )
  end
end
