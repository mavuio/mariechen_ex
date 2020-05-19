defmodule Mariechen.Core.Tags.ProductVariants do
  @moduledoc false
  alias Mariechen.Repo
  alias Mariechen.Core.Schemas.ProductVariant
  alias Mariechen.Core.Tags
  # alias Mariechen.Core.Schemas.VariantTag
  import Ecto.Query, warn: false

  def get_product_variant_query() do
    ProductVariant
    |> join(:left, [p], s in assoc(p, :site_tree))
    |> where([p, s], s.class_name == "ProductVariant")
    |> select([p, s], %{
      id: p.id,
      new_tags: p.new_tags
    })
  end

  def get_product_variant_by_id(id) when is_integer(id) do
    get_product_variant_query()
    |> where([p, s], s.id == ^id)
    |> Repo.one()
  end

  def handle_new_tags_on_variant_id(id) when is_integer(id) do
    get_product_variant_by_id(id)
    |> case do
      %{new_tags: "#" <> _ = new_tags} ->
        new_tags |> IO.inspect(label: "handle_new_tags_on_variant #{id}")
        Tags.set_tags_for_page(id, new_tags)

      _ ->
        nil
    end
  end
end
