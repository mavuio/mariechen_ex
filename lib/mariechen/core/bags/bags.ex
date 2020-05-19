defmodule Mariechen.Core.Bags do
  @moduledoc false
  alias Mariechen.Repo
  alias Mariechen.Core.Schemas.ProductVariant
  alias Mariechen.Core.Schemas.FileTag
  alias Mariechen.Core.Schemas.MwFile
  alias Mariechen.Core.Tags
  alias Kandis.KdError
  alias Kandis.KdPagination

  import Ecto.Query, warn: false
  import Kandis.KdHelpers
  use Memoize

  @default_per_page 24

  def get_bag_count(params \\ %{}) do
    params = expand_tag_ids_in_params(params)

    query = get_bag_query(params)

    count_query_sql =
      query
      |> exclude(:select)
      |> select([a, b, c], fragment("count(*)"))
      |> get_fixed_sql_for_query()

    {:ok, %{rows: [[total_count]]}} =
      Repo.query(elem(count_query_sql, 0), elem(count_query_sql, 1))

    total_count
  end

  def get_bags(params \\ %{}) do
    params = expand_tag_ids_in_params(params)

    query = get_bag_query(params)

    per_page = array_get(params, "per_page", @default_per_page)

    limited_query = KdPagination.limit_query(query, params["page"], per_page: per_page)

    count_query_sql =
      query
      |> exclude(:select)
      |> select([a, b, c], fragment("count(*)"))
      |> get_fixed_sql_for_query()

    fixed_limited_query_sql = limited_query |> get_fixed_sql_for_query()

    {:ok, result} = Repo.query(elem(fixed_limited_query_sql, 0), elem(fixed_limited_query_sql, 1))

    items =
      result.rows
      |> Enum.map(fn row ->
        create_map_from_values(
          row,
          ~w(pv_id p_id p_title p_url pv_url pv_in_stock title p_file_root_id p_category p_price)a
        )
      end)
      |> augment_bags_with_files(params)
      |> Enum.filter(fn bag ->
        case bag[:files] do
          nil -> false
          [] -> false
          _ -> true
        end
      end)

    {:ok, %{rows: [[total_count]]}} =
      Repo.query(elem(count_query_sql, 0), elem(count_query_sql, 1))

    log(params, "get_bags", :info)
    KdPagination.page({items, total_count}, params["page"], per_page: per_page)
  end

  def get_bag_for_cart(pv_id, params \\ %{}), do: get_bag(pv_id, params)

  defmemo get_bag(pv_id, params \\ %{}) when is_integer(pv_id), expires_in: 1800_000 do
    query =
      get_bag_query(Map.merge(params, %{"pv_id" => pv_id}))
      |> get_fixed_sql_for_query()

    {:ok, result} = Repo.query(elem(query, 0), elem(query, 1))

    result.rows
    |> Enum.map(fn row ->
      create_map_from_values(
        row,
        ~w(pv_id p_id title p_url url pv_in_stock subtitle p_file_root_id p_category price)a
      )
    end)
    |> augment_bags_with_files(params)
    |> Enum.at(0)
  end

  def create_map_from_values(values, keys) when is_list(keys) and is_list(values) do
    Enum.map_reduce(keys, values, fn key_atom, [value | rest_values] ->
      {{key_atom, value}, rest_values}
    end)
    |> elem(0)
    |> Map.new()
  end

  def get_fixed_sql_for_query(query) do
    {sql, params} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)

    expand_list_arguments_in_query({sql, params})
  end

  def expand_list_arguments_in_query({sql, arguments})
      when is_list(arguments) and is_binary(sql) do
    sqlparts =
      sql
      |> String.split("?")

    if(Enum.count(arguments) !== Enum.count(sqlparts) - 1) do
      {Enum.count(arguments), Enum.count(sqlparts), arguments, sql}
      |> KdError.die(label: "sql & arguments do not match ")
    end

    sql =
      Enum.map_reduce(sqlparts, arguments, fn element, arguments ->
        case arguments do
          [head | tail] ->
            markers =
              [head]
              |> List.flatten()
              |> Enum.map(fn _ -> "?" end)
              |> Enum.join(",")

            result = {element, markers}
            {result, tail}

          [] ->
            result = {element, ""}
            {result, []}
        end
      end)
      |> elem(0)
      |> Enum.map(fn {sql, markers} -> sql <> markers end)
      |> Enum.join("")

    flat_arguments = List.flatten(arguments)
    {sql, flat_arguments}
  end

  def expand_tag_ids_in_params(params) do
    Map.to_list(params)
    |> Enum.flat_map(fn {key, val} ->
      case key do
        "tags" <> <<_::bytes-size(1)>> ->
          [{key, val}, {key <> "_ids", Tags.get_tag_ids_from_string(val, :include_children)}]

        _ ->
          [{key, val}]
      end
    end)
    |> Map.new()
  end

  def augment_bags_with_files(bags, params) when is_list(bags) do
    Enum.map(bags, fn bag -> augment_bag_with_files(bag, params) end)
  end

  def augment_bag_with_files(bag, params) when is_map(bag) do
    Map.put(bag, :files, get_file_ids_for_bag(bag, params))
  end

  def get_file_ids_for_bag(bag, _params) when is_map(bag) do
    # get_file_query(bag, params)
    # |> Repo.all()
    # |> filter_best_files_for_params(params)

    ids_of_product_variant = Tags.get_tag_ids_for_page(bag.pv_id)

    get_file_ids_for_file_root_id(bag[:p_file_root_id])
    |> Enum.filter(fn {_id, tag_id_string} ->
      tag_id_string_contains_id_list?(tag_id_string, ids_of_product_variant)
    end)
    |> Enum.map(fn {file_id, tag_str} -> %{url: get_file_url(file_id), tags: tag_str} end)
    |> Enum.take(2)
  end

  def tag_id_string_contains_id_list?(tag_id_string, contains_id_list)
      when is_binary(tag_id_string) and is_list(contains_id_list) do
    tag_ids =
      tag_id_string
      |> String.split(",")
      |> Enum.map(&to_int/1)

    contains_id_list -- tag_ids == []
  end

  def tag_id_string_contains_id_list?(nil, id_list)
      when is_list(id_list) do
    tag_id_string_contains_id_list?("", id_list)
  end

  def get_file_ids_for_file_root_id(nil) do
    []
  end

  def get_file_ids_for_file_root_id(file_root_id) when is_integer(file_root_id) do
    get_file_query(file_root_id)
    |> Repo.all()
  end

  def filter_best_files_for_params(files, params) when is_list(files) do
    log(params)

    get_tag_ids_to_filter_from_params(params)
    |> Enum.map(fn {key, tag_id_list} ->
      filtered_files = filter_files_by_tag_ids(files, tag_id_list)
      {key, filtered_files, Enum.count(filtered_files)}
    end)
    |> Enum.filter(fn {_, _, cnt} -> cnt > 0 end)
    |> Enum.sort(fn {_, _, a}, {_, _, b} -> a < b end)
    |> case do
      [] -> files
      list -> list |> hd() |> elem(1)
    end
  end

  def filter_files_by_tag_ids(files, search_tag_id_list) do
    files
    |> Enum.filter(fn {_file_id, tag_id_str} ->
      get_id_list_from_tag_id_str(tag_id_str)
      |> Enum.any?(fn file_tag_id -> Enum.member?(search_tag_id_list, file_tag_id) end)
    end)
  end

  def get_id_list_from_tag_id_str(nil) do
    []
  end

  def get_id_list_from_tag_id_str(tag_id_str) when is_binary(tag_id_str) do
    String.split(tag_id_str, ",")
    |> Enum.map(fn a -> to_int(a) end)
  end

  def get_tag_ids_to_filter_from_params(params) do
    Map.to_list(params)
    |> Enum.filter(fn {key, _val} ->
      case key do
        "tags" <> <<_digit::bytes-size(1)>> <> "_ids" -> true
        _ -> false
      end
    end)
  end

  def get_image_folder_url_for_product(p_url) when is_binary(p_url) do
    "/products/" <> p_url
  end

  def get_file_query(file_root_id) when is_integer(file_root_id) do
    MwFile
    |> join(:left, [f], ft in FileTag, on: ft.file_id == f.id)
    |> where([f, _], f.parent_id == ^file_root_id)
    |> order_by([f, _], asc: f.sort)
    |> group_by([f, ft], [f.id])
    |> select([f, ft], {f.id, fragment("GROUP_CONCAT(?)", ft.tag_id)})
  end

  defmemo get_file_url(file_id), expires_in: 86400 * 30 do
    base_url = Application.get_env(:mariechen, :config)[:local_url]
    url = '#{base_url}/TagNode/image/#{file_id}'

    {:ok, {_result, headers, _body}} =
      :httpc.request(:get, {url, []}, [{:autoredirect, false}], [])

    headers
    |> Enum.filter(fn {key, _val} -> key == 'location' end)
    |> case do
      [] ->
        url |> List.to_string()

      found ->
        found
        |> hd()
        |> elem(1)
        |> List.to_string()
    end
    |> String.replace_leading(base_url, "")
  end

  defmacro tags_contain(id, parent_id, tag_ids) do
    quote do
      fragment(
        "exists(select pt.tag_id from page_tag pt where (pt.page_id=? or pt.page_id=? ) and pt.tag_id in (?) )",
        unquote(id),
        unquote(parent_id),
        unquote(tag_ids)
      )
    end
  end

  def bag_has_tags(pv_id, tagstrings) when is_integer(pv_id) and is_list(tagstrings) do
    params = %{"pv_id" => pv_id, "tags1" => tagstrings |> Enum.at(0)}

    case get_bag_count(params) |> IO.inspect(label: "mwuits-debug 2020-04-09_14:49 ") do
      1 -> true
      _ -> false
    end
  end

  def get_bag_query(params) do
    lang = array_get(params, "lang", "en")

    tagfilters =
      ~w(tags1 tags2 tags3 tags4)
      |> Enum.map(fn param_name ->
        {String.to_atom(param_name),
         case params[param_name <> "_ids"] do
           nil ->
             nil

           [] ->
             nil

           list when is_list(list) ->
             list

           str when is_binary(str) ->
             str |> Tags.get_tag_ids_from_string()
         end}
      end)
      |> Map.new()

    log(params)

    # tagfilter1 = [24, 22] |> Enum.join(",")
    # usages = usages |> Enum.join(",")

    is_hidden = false

    query =
      ProductVariant
      |> join(:inner, [pv], pvs in assoc(pv, :site_tree))
      |> join(:inner, [pv, pvs], ps in assoc(pvs, :site_tree_parent))
      |> join(:inner, [pv, pvs, ps], p in assoc(ps, :product_page))
      |> join(:inner, [pv, pvs, ps, p], c in assoc(ps, :site_tree_parent))
      # |> join(:inner, [pv, pvs, ps], pt in PageTag, on: pt.page_id == s.id or pt.page_id == s.parent_id)
      # |> join(:inner, [pv, pvs, ps], ptcolors in PageTag, on: pt.page_id == s.id or pt.page_id == s.parent_id)
      # |> join(:inner, [pv, pvs, ps, pt, t], t in assoc(pt, :tag_node))
      |> pipe_when(
        tagfilters.tags1,
        where(
          [pv, pvs, ps, p, c],
          tags_contain(
            pvs.id,
            pvs.parent_id,
            ^tagfilters.tags1
          )
        )
      )
      |> pipe_when(
        tagfilters.tags2,
        where(
          [pv, pvs, ps, p, c],
          tags_contain(
            pvs.id,
            pvs.parent_id,
            ^tagfilters.tags2
          )
        )
      )
      |> pipe_when(
        tagfilters.tags3,
        where(
          [pv, pvs, ps, p, c],
          tags_contain(
            pvs.id,
            pvs.parent_id,
            ^tagfilters.tags3
          )
        )
      )
      |> pipe_when(
        tagfilters.tags4,
        where(
          [pv, pvs, ps, p, c],
          tags_contain(
            pvs.id,
            pvs.parent_id,
            ^tagfilters.tags4
          )
        )
      )
      |> pipe_when(
        params["pv_id"],
        where(
          [pv, pvs, ps, p, c],
          pv.id == ^params["pv_id"]
        )
      )
      |> pipe_when(
        is_nil(params["pv_id"]),
        where([pv, pvs, ps, p, c], pvs.hidden == ^is_hidden and ps.hidden == ^is_hidden)
      )
      |> where([pv, pvs, ps, p, c], pv.in_stock > 0)
      # |> group_by([pv, pvs, ps], [pv.id, s.url_segment, s.title])
      # |> join(:left, [pv, pvs, ps], f in MwFile,
      #   on:
      #     f.parent_id ==
      #       fragment("SELECT ID from MwFile f1 where Filename=concat('/products/','corolla')")
      # )
      # |> join(:inner, [pv, pvs, ps, f], ft in FileTag,
      #   on:
      #     fragment(
      #       "? = ?
      #       and ? in (select tag_id from page_tag where page_id = ?)",
      #       ft.file_id,
      #       f.id,
      #       ft.tag_id,
      #       pv.id
      #     )
      # )

      |> pipe_when(
        lang == "en",
        select([pv, pvs, ps, p, c], %{
          pv_id: pv.id,
          p_id: ps.id,
          p_title: ps.title,
          p_url: ps.url_segment,
          pv_url: pvs.url_segment,
          pv_in_stock: pv.in_stock,
          title: pvs.title,
          p_file_root_id: p.file_root_id,
          p_category: c.url_segment,
          p_price: p.price
          # f: f.filename,
          # files: fragment("GROUP_CONCAT(?)", f.id)

          # hidden: s.hidden,
          # tag_id: pt.tag_id,
          # tag: t.url_segment
          # tag_ids: fragment("GROUP_CONCAT(?)", t.id)
        })
      )
      |> pipe_when(
        lang == "de",
        select([pv, pvs, ps, p, c], %{
          pv_id: pv.id,
          p_id: ps.id,
          p_title: p.title_de |> coalesce(ps.title),
          p_url: ps.url_segment,
          pv_url: pvs.url_segment,
          pv_in_stock: pv.in_stock,
          title: pv.title_de |> coalesce(pvs.title),
          p_file_root_id: p.file_root_id,
          p_category: c.url_segment,
          p_price: p.price
          # f: f.filename,
          # files: fragment("GROUP_CONCAT(?)", f.id)

          # hidden: s.hidden,
          # tag_id: pt.tag_id,
          # tag: t.url_segment
          # tag_ids: fragment("GROUP_CONCAT(?)", t.id)
        })
      )
      |> order_by([pv, pvs, ps, p, c], asc: c.sort, asc: ps.sort)

    query
  end
end
