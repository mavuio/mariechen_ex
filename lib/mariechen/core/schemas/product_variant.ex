defmodule Mariechen.Core.Schemas.ProductVariant do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mariechen.Core.Schemas.SiteTree
  # alias Mariechen.Core.Schemas.TagNode
  alias Mariechen.Core.Schemas.PageTag

  @primary_key {:ID, :id, autogenerate: true}
  schema "ProductVariant_Live" do
    field(:new_tags, :string, source: :newtags)
    field(:title_de, :string)
    field(:variant_nr, :string, source: :variantnr)
    field(:in_stock, :integer, source: :instock)
    field(:effective_stock, :integer, source: :effectivestock)

    belongs_to :site_tree, SiteTree, foreign_key: :id

    many_to_many(
      :tag_node,
      SiteTree,
      join_through: PageTag
    )
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :new_tags,
      :in_stock,
      :effective_stock
    ])
  end
end
