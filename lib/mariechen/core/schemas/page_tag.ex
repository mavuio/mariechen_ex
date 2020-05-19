defmodule Mariechen.Core.Schemas.PageTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mariechen.Core.Schemas.SiteTree

  schema "page_tag" do
    # field(:page_id, :integer)
    # field(:tag_id, :integer)
    belongs_to :site_tree, SiteTree, foreign_key: :page_id
    belongs_to :tag_node, SiteTree, foreign_key: :tag_id
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :page_id,
      :tag_id
    ])
    |> unique_constraint(:page_id, name: :page_tag_page_id_tag_id_index)
  end
end
