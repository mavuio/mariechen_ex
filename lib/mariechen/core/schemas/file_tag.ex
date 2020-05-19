defmodule Mariechen.Core.Schemas.FileTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mariechen.Core.Schemas.MwFile

  schema "file_tag" do
    # field(:file_id, :integer)
    # field(:tag_id, :integer)
    belongs_to :site_tree, MwFile, foreign_key: :file_id
    belongs_to :tag_node, MwFile, foreign_key: :tag_id
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :file_id,
      :tag_id
    ])
  end
end
