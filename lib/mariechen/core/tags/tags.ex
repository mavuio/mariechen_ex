defmodule Mariechen.Core.Tags do
  @moduledoc false
  alias Mariechen.Repo
  alias Mariechen.Core.Schemas.SiteTree
  alias Mariechen.Core.Schemas.TagNode
  alias Mariechen.Core.Schemas.PageTag
  alias Mariechen.Core.Schemas.FileTag

  import Ecto.Query, warn: false

  @tag_root_folder_id 6

  def get_type(type) do
    get_tag_query()
    |> where([t, s], s.url_segment == ^type)
    |> where([t, s], s.parent_id == @tag_root_folder_id)
    |> Repo.one()
  end

  def get_children(%{:id => tag_id} = _tag, lang \\ "de") do
    get_tag_query(lang)
    |> where([t, s], s.parent_id == ^tag_id)
    |> order_by([t, s], asc: s.sort)
    |> Repo.all()
  end

  def get_children_ids(tag_id) when is_integer(tag_id) do
    get_small_tag_query()
    |> exclude(:select)
    |> select([s], s.id)
    |> where([s], s.parent_id == ^tag_id)
    |> Repo.all()
  end

  def get_all_children_as_tree(tag, lang \\ "de") do
    get_children(tag, lang)
    |> Enum.map(fn ctag ->
      childs = get_all_children_as_tree(ctag, lang)

      case Enum.count(childs) do
        0 -> Map.put(ctag, :children, nil)
        _ -> Map.put(ctag, :children, childs)
      end
    end)
  end

  def get_all_children_as_list(tag, lang \\ "de") do
    get_children(tag, lang)
    |> Enum.flat_map(fn ctag ->
      [ctag | get_all_children_as_list(ctag, lang)]
    end)
  end

  def get_tag_query() do
    get_tag_query("de")
  end

  def get_tag_query("de") do
    TagNode
    |> join(:left, [t], s in assoc(t, :site_tree))
    |> where([t, s], s.class_name == "TagNode")
    |> select([t, s], %{
      id: t.id,
      key: s.url_segment,
      parent_id: s.parent_id,
      title: s.title
    })
  end

  def get_tag_query("en") do
    TagNode
    |> join(:left, [t], s in assoc(t, :site_tree))
    |> where([t, s], s.class_name == "TagNode")
    |> select([t, s], %{
      id: t.id,
      key: s.url_segment,
      parent_id: s.parent_id,
      title: coalesce(t.title_en, s.title)
    })
  end

  def get_small_tag_query() do
    SiteTree
    |> where([s], s.class_name == "TagNode")
    |> select([s], %{
      id: s.id,
      key: s.url_segment,
      parent_id: s.parent_id,
      title: s.title
    })
  end

  def get_tag_by_key(key) when is_binary(key) do
    key = key |> String.replace_leading("#", "")

    case Integer.parse(key) do
      {tag_id, ""} ->
        get_tag_by_id(tag_id)

      _ ->
        get_tag_query()
        |> where([t, s], s.url_segment == ^key)
        |> Repo.one()
        |> add_type()
    end
  end

  def get_tag_by_id(id) when is_integer(id) do
    get_tag_query()
    |> where([t, s], s.id == ^id)
    |> Repo.one()
    |> add_type()
  end

  def add_type(%{parent_id: _} = rec) do
    type = get_typename_of_tag(rec)
    Map.put(rec, :type, type)
  end

  def add_type(rec) do
    rec
  end

  def get_typename_of_tag(rec) do
    case rec.parent_id do
      @tag_root_folder_id ->
        rec.key

      0 ->
        "n/a"

      -1 ->
        "n/a"

      _ ->
        rec
        |> get_minimal_parent_rec()
        |> get_typename_of_tag()
    end
  end

  def get_minimal_parent_rec(rec) do
    SiteTree
    |> where([s], s.id == ^rec.parent_id)
    |> select([s], %{key: s.url_segment, parent_id: s.parent_id})
    |> Repo.one()
  end

  def get_tags_from_string(string) when is_binary(string) do
    string
    |> String.split()
    |> Enum.map(&get_tag_by_key/1)
    |> Enum.filter(fn a -> not is_nil(a) end)
  end

  def get_tags_from_string(taglist) when is_list(taglist) do
    taglist
  end

  def get_tag_ids_from_string(nil) do
    []
  end

  def get_tag_ids_from_string(string) when is_binary(string) do
    string
    |> String.split([" ", ","])
    |> Enum.map(&get_tag_by_key/1)
    |> Enum.filter(fn a -> not is_nil(a) end)
    |> Enum.map(fn tag -> tag.id end)
  end

  def get_tag_ids_from_string(string_or_nil, :include_children) do
    get_tag_ids_from_string(string_or_nil)
    |> Enum.flat_map(fn tag_id ->
      [tag_id] ++ get_children_ids(tag_id)
    end)
  end

  def set_tags_for_record("SiteTree-" <> page_id, tags) do
    page_id = String.to_integer(page_id)
    set_tags_for_page(page_id, tags)
  end

  def set_tags_for_record("MwFile-" <> file_id, tags) do
    file_id = String.to_integer(file_id)
    set_tags_for_file(file_id, tags)
  end

  def get_tags_for_record("SiteTree-" <> page_id) do
    page_id = String.to_integer(page_id)
    get_tags_for_page(page_id)
  end

  def get_tags_for_record("MwFile-" <> file_id) do
    file_id = String.to_integer(file_id)
    get_tags_for_file(file_id)
  end

  def get_tags_for_file(file_id) when is_integer(file_id) do
    FileTag
    |> where([pt], pt.file_id == ^file_id)
    |> Repo.all()
    |> Enum.map(fn tagrec -> get_tag_by_id(tagrec.tag_id) end)
    |> Enum.filter(fn a -> not is_nil(a) end)
  end

  def get_tags_for_page(page_id) when is_integer(page_id) do
    PageTag
    |> where([pt], pt.page_id == ^page_id)
    |> Repo.all()
    |> Enum.map(fn tagrec -> get_tag_by_id(tagrec.tag_id) end)
    |> Enum.filter(fn a -> not is_nil(a) end)
  end

  def get_tag_ids_for_page(page_id) when is_integer(page_id) do
    get_tags_for_page(page_id)
    |> Enum.map(fn a -> a.id end)

    # |> Enum.map(fn tagrec -> get_tag_by_id(tagrec.tag_id) end)
  end

  def add_tag_to_page(tag, page_id) when is_map(tag) and is_integer(page_id) do
    PageTag.changeset(%PageTag{}, %{page_id: page_id, tag_id: tag.id})
    |> Repo.insert()
  end

  def remove_tag_from_page(tag, page_id) when is_map(tag) and is_integer(page_id) do
    PageTag
    |> where([pt], pt.page_id == ^page_id)
    |> where([pt], pt.tag_id == ^tag.id)
    |> Repo.delete_all()
  end

  def set_tags_for_page(page_id, nil) when is_integer(page_id) do
    PageTag
    |> where([pt], pt.page_id == ^page_id)
    |> Repo.delete_all()
  end

  def set_tags_for_page(page_id, tags) when is_integer(page_id) do
    target_tags = get_tags_from_string(tags)
    tags_already_set = get_tags_for_page(page_id)

    tags2add = target_tags -- tags_already_set
    tags2remove = tags_already_set -- target_tags

    tags2add
    |> Enum.map(fn tag ->
      add_tag_to_page(tag, page_id)
    end)

    tags2remove
    |> Enum.map(fn tag ->
      remove_tag_from_page(tag, page_id)
    end)
  end

  def add_tag_to_file(tag, file_id) when is_map(tag) and is_integer(file_id) do
    FileTag.changeset(%FileTag{}, %{file_id: file_id, tag_id: tag.id})
    |> Repo.insert()
  end

  def remove_tag_from_file(tag, file_id) when is_map(tag) and is_integer(file_id) do
    FileTag
    |> where([pt], pt.file_id == ^file_id)
    |> where([pt], pt.tag_id == ^tag.id)
    |> Repo.delete_all()
  end

  def set_tags_for_file(file_id, nil) when is_integer(file_id) do
    FileTag
    |> where([pt], pt.file_id == ^file_id)
    |> Repo.delete_all()
  end

  def set_tags_for_file(file_id, tags) when is_integer(file_id) do
    target_tags = get_tags_from_string(tags)
    tags_already_set = get_tags_for_file(file_id)

    tags2add = target_tags -- tags_already_set
    tags2remove = tags_already_set -- target_tags

    tags2add
    |> Enum.map(fn tag ->
      add_tag_to_file(tag, file_id)
    end)

    tags2remove
    |> Enum.map(fn tag ->
      remove_tag_from_file(tag, file_id)
    end)
  end

  def get_tag_string_from_list(tags) when is_list(tags) do
    tags
    |> Enum.map(fn tag -> "#" <> tag.key end)
    |> Enum.join(" ")
  end

  def get_tags_for_type(type_name) when is_binary(type_name) do
    type = get_type(type_name)

    case type do
      nil ->
        []

      type ->
        get_all_children_as_list(type) |> Enum.map(fn tag -> Map.put(tag, :type, type.key) end)
    end
  end

  def get_tag_tree_for_type(type_name, lang \\ "de") when is_binary(type_name) do
    type = get_type(type_name)

    case type do
      nil ->
        []

      type ->
        get_all_children_as_tree(type, lang)
        # |> Enum.map(fn tag -> Map.put(tag, :type, type.key) end)
    end
  end

  def update_tags_on_multiple_records(taggable_ids, add_tags, remove_tags)
      when is_binary(taggable_ids) do
    update_tags_on_multiple_records(taggable_ids |> String.split(","), add_tags, remove_tags)
  end

  def update_tags_on_multiple_records(taggable_ids, add_tags, remove_tags)
      when is_list(taggable_ids) do
    taggable_ids
    |> Enum.map(fn record_id ->
      update_tags_on_record(record_id, add_tags, remove_tags)
    end)
  end

  def update_tags_on_record("SiteTree-" <> page_id, add_tags, remove_tags) do
    page_id = String.to_integer(page_id)
    tags2add = get_tags_from_string(add_tags)
    tags2remove = get_tags_from_string(remove_tags)

    tags2add
    |> Enum.map(fn tag ->
      add_tag_to_page(tag, page_id)
    end)

    tags2remove
    |> Enum.map(fn tag ->
      remove_tag_from_page(tag, page_id)
    end)
  end

  def update_tags_on_record("MwFile-" <> file_id, add_tags, remove_tags) do
    file_id = String.to_integer(file_id)
    tags2add = get_tags_from_string(add_tags)
    tags2remove = get_tags_from_string(remove_tags)

    tags2add
    |> Enum.map(fn tag ->
      add_tag_to_file(tag, file_id)
    end)

    tags2remove
    |> Enum.map(fn tag ->
      remove_tag_from_file(tag, file_id)
    end)
  end
end
