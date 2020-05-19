defmodule MariechenWeb.TagsController do
  use MariechenWeb, :controller

  alias Mariechen.Core.Tags
  alias Mariechen.Core.Tags.ProductPages
  alias Mariechen.Core.Tags.ProductVariants

  def get_tags_for_types(conn, %{"types" => types_str}) do
    res =
      types_str
      |> String.split(",")
      |> Enum.map(fn type_name ->
        {type_name, Tags.get_tags_for_type(type_name) |> convert_taglist_for_vue_tags_input()}
      end)
      |> Map.new()

    json(conn, %{payload: res})
  end

  def get_tag_tree_for_types(conn, %{"types" => types_str, "lang" => lang}) do
    res =
      types_str
      |> String.split(",")
      |> Enum.map(fn type_name ->
        {type_name, Tags.get_tag_tree_for_type(type_name, lang)}
      end)
      |> Map.new()

    json(conn, %{payload: res})
  end

  def get_tags_for_string(conn, %{"tag_string" => tag_string}) do
    res = Tags.get_tags_from_string(tag_string) |> convert_taglist_for_vue_tags_input()

    json(conn, %{payload: res})
  end

  def get_tags_for_record(conn, %{"record" => record}) do
    res = Tags.get_tags_for_record(record) |> convert_taglist_for_vue_tags_input()

    json(conn, %{payload: res})
  end

  def set_tags_for_record(conn, %{"record" => record, "tag_string" => tag_string}) do
    Tags.set_tags_for_record(record, tag_string)

    json(conn, %{payload: get_tags_for_record(conn, %{"record" => record})})
  end

  def update_tags_on_multiple_records(
        conn,
        %{
          "taggable_ids" => taggable_ids,
          "add_tags" => add_tags,
          "remove_tags" => remove_tags
        } = _params
      ) do
    # res = Tags.set_tags_for_record(record, tag_string)

    res = Tags.update_tags_on_multiple_records(taggable_ids, add_tags, remove_tags)

    json(conn, %{payload: res})
  end

  def touch_product_page(conn, %{"id" => id_str}) do
    id = String.to_integer(id_str)
    ProductPages.handle_new_tags_on_page_id(id)

    res = Tags.get_tags_for_page(id)
    json(conn, %{payload: res})
  end

  def touch_product_variant(conn, %{"id" => id_str}) do
    id = String.to_integer(id_str)
    ProductVariants.handle_new_tags_on_variant_id(id)

    res = Tags.get_tags_for_page(id)
    json(conn, %{payload: res})
  end

  def convert_taglist_for_vue_tags_input(tags) when is_list(tags) do
    Enum.map(tags, &convert_tag_for_vue_tags_input/1)
  end

  def convert_tag_for_vue_tags_input(tag) when is_map(tag) do
    %{
      "key" => tag[:key],
      "classes" => "ti-" <> tag[:type],
      "text" => tag[:key]
    }
  end
end
