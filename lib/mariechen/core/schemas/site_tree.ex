defmodule Mariechen.Core.Schemas.SiteTree do
  use Ecto.Schema
  import Ecto.Changeset

  alias Mariechen.Core.Schemas.TagNode
  alias Mariechen.Core.Schemas.SiteTree
  alias Mariechen.Core.Schemas.PageTag
  alias Mariechen.Core.Schemas.ProductPage

  @primary_key {:id, :id, autogenerate: true}
  schema "SiteTree_Live" do
    field(:last_edited, :naive_datetime, source: :lastedited)
    field(:created, :naive_datetime, source: :created)
    field(:url_segment, :string, source: :urlsegment)
    field(:class_name, :string, source: :classname)
    field(:title, :string, source: :title)
    field(:menu_title, :string, source: :menutitle)
    field(:sort, :integer, source: :sort)
    field(:report_class, :string, source: :reportclass)
    field(:version, :integer, source: :version)
    field(:hide_on, :naive_datetime, source: :hideon)
    field(:publish_on, :naive_datetime, source: :publishon)
    field(:archive_on, :naive_datetime, source: :archiveon)
    field(:parent_id, :integer, source: :parentid)
    field(:hidden, :boolean, source: :hidden)
    field(:show_in_menus, :boolean, source: :showinmenus)
    has_one :tag_node, TagNode

    has_one :site_tree_parent, SiteTree, references: :parent_id, foreign_key: :id
    has_one :product_page, ProductPage, references: :id, foreign_key: :id

    many_to_many(
      :pv_tags,
      SiteTree,
      join_through: PageTag,
      join_keys: [page_id: :id, tag_id: :id]
    )
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(
      params,
      [
        :last_edited,
        :created,
        :url_segment,
        :class_name,
        :title,
        :menu_title,
        :sort,
        :report_class,
        :version,
        :hide_on,
        :publish_on,
        :archive_on,
        :parent_id,
        :hidden,
        :show_in_menus
      ]
    )
    |> validate_required([:ParentID, :Title, :ClassName])
  end
end
