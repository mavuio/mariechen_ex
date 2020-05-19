defmodule Mariechen.Core.Schemas.TagNode do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mariechen.Core.Schemas.SiteTree
  alias Mariechen.Core.Schemas.PageTag
  alias Mariechen.Core.Schemas.ProductVariant

  @primary_key {:ID, :id, autogenerate: true}
  schema "TagNode_Live" do
    field(:title_en, :string, source: :title_en)
    belongs_to :site_tree, SiteTree, foreign_key: :id

    many_to_many(
      :product_variant,
      ProductVariant,
      join_through: PageTag
    )
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :title_en
    ])
  end
end
