defmodule Mariechen.Core.Schemas.ProductPage do
  use Ecto.Schema
  import Ecto.Changeset
  alias Mariechen.Core.Schemas.SiteTree

  @primary_key {:ID, :id, autogenerate: true}
  schema "ProductPage_Live" do
    field(:new_tags, :string, source: :newtags)
    field(:price, :decimal)
    field(:title_de, :string)
    field(:product_nr, :string, source: :productnr)
    field(:file_root_id, :integer, source: :filerootid)
    belongs_to :site_tree, SiteTree, foreign_key: :id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :id,
      :new_tags
    ])
  end
end
