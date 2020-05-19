defmodule Mariechen.Core.Stock do
  @moduledoc false
  use Memoize

  alias Mariechen.Core.Schemas.ProductPage
  alias Mariechen.Core.Schemas.ProductVariant
  alias Mariechen.Repo
  alias Mariechen.Core.Schemas.SkuInOrders
  import Ecto.Query, warn: false
  import Kandis.KdHelpers

  defmemo get_cached_stock_csv_data(), expires_in: 86_400_000 do
    get_stock_csv_data()
  end

  def get_stock_csv_data(opts \\ []) do
    if Keyword.get(opts, :cache) do
      get_cached_stock_csv_data()
    else
      fetch_url("https://mariechen.com/csv/LAGERBESTAND.CSV")
    end
  end

  def get_stock_data(opts \\ []) do
    get_stock_csv_data(opts)
    |> parse_csv_data(opts)
  end

  def write_stock_data(opts \\ []) do
    Kandis.KdHelpers.log("start", "WRITING STOCK-DATA", :info)
    reset_stock_counts()

    get_stock_data(opts)
    |> Enum.map(&handle_stock_line(&1, opts))
    |> Enum.filter(fn a -> not is_nil(a) end)

    update_effective_stock_for_all_products()
    Kandis.KdHelpers.log("end", "WRITING STOCK-DATA", :info)
  end

  def handle_stock_line(%{prodnr: prodnr, color: color, qty: qty}, _opts) do
    # find product
    get_product_variant(prodnr, color)
    |> case do
      %ProductVariant{} = variant -> variant |> set_stock_for_variant(qty)
      list when is_list(list) -> list
      nil -> nil
    end
  end

  def handle_stock_line(_, _), do: nil

  def set_stock_for_variant(%ProductVariant{} = v, qty) do
    qty =
      qty
      |> Decimal.new()
      |> to_int()

    v
    |> ProductVariant.changeset(%{"in_stock" => qty})
    |> Repo.update!()
  end

  def reset_stock_counts() do
    Repo.update_all(ProductVariant |> where([i], i.in_stock < 1000), set: [in_stock: nil])
  end

  def get_product_by_nr(nr) do
    Repo.get_by(ProductPage, product_nr: nr)
  end

  def get_product_variant(prodnr, color) do
    color = String.trim(color)

    variants =
      ProductVariant
      |> join(:left, [pv], pvs in assoc(pv, :site_tree))
      |> join(:left, [pv, pvs], ps in assoc(pvs, :site_tree_parent))
      |> join(:left, [pv, pvs, ps], p in assoc(ps, :product_page))
      |> where([pv, pvs, ps, p], fragment("trim(?)", pv.variant_nr) == ^color)
      |> where([pv, pvs, ps, p], fragment("trim(?)", p.product_nr) == ^prodnr)
      |> select([pv, pvs, ps, p], {pv.id, pvs.title, p.product_nr, pv.variant_nr})
      |> Repo.all()

    # |> Enum.filter(fn {_, _, _, pv_variant_nr} ->
    #   pv_variant_nr == color
    # end)

    case length(variants) do
      0 ->
        nil

      1 ->
        id = variants |> Enum.at(0) |> elem(0)

        Repo.get(ProductVariant, id)

      # _ -> variants
      _ ->
        raise "too many items match #{prodnr},#{color}"
    end

    # |> KdError.die(label: "mwuits-debug 2020-03-20_22:04 ")
  end

  def parse_csv_data(data, opts) do
    data
    |> String.split("\r\n")
    |> CSV.decode!(
      separator: ?\t,
      preprocessor: :none,
      strip_fields: true,
      validate_row_length: false,
      headers: ~w(prodnr name1 name2 name3 name4 price color qty)a
    )
    |> Stream.drop(1)
    |> Enum.take(Keyword.get(opts, :take, 1_000_000))
  end

  def fetch_url(url) do
    url = '#{url}'

    {:ok, {_result, _headers, body}} =
      :httpc.request(:get, {url, []}, [{:autoredirect, false}], [])

    body |> to_string()
  end

  def update_effective_stock_for_all_products() do
    "update_effective_stock_for_all_products"
    |> IO.inspect(label: "mwuits-debug 2020-04-18_21:12 ")

    reset_effective_stock()

    get_sku_amounts_in_orders()
    |> Enum.map(&set_effective_stock_for_sku(&1.sku, &1.amount))
  end

  def set_effective_stock_for_sku(sku, amount) do
    ProductVariant
    |> select([:ID, :in_stock])
    |> where([p], p.id == type(^sku, :integer))
    |> Repo.one()
    |> case do
      nil ->
        :failed

      rec ->
        rec
        |> ProductVariant.changeset(%{effective_stock: rec.in_stock - to_int(amount)})
        |> Repo.update()
        |> elem(0)
    end
  end

  def get_sku_amounts_in_orders() do
    SkuInOrders
    |> join(:left, [so], o in assoc(so, :order))
    |> where([so, o], o.state not in ~w(cancelled))
    |> group_by([so, o], [so.sku, o.state])
    |> select([so, o], %{sku: so.sku, state: o.state, amount: fragment("SUM(?)", so.amount)})
    |> Repo.all()
  end

  def reset_effective_stock() do
    from(p in ProductVariant,
      where: fragment("nvl(?,0)", p.in_stock) != fragment("nvl(?,0)", p.effective_stock),
      update: [set: [effective_stock: p.in_stock]]
    )
    |> Repo.update_all([])
  end

  # order.csv line:
  # EBS0124;09.02.2020;971;Kofler;Anna;;Weinberggasse 60/18/7;1190;Wien;at;Kofler;Anna;;Weinberggasse 60/18/7;1190;Wien;at;;anna.s.kofler@gmail.com;A2708705;Twisterette L/S;;170.00;1;5
  # p_documentnumber;p_timestamp;pp_id;pp_lastname_1;pp_firstname_1;pp_gender;pp_street_1;pp_postal_1;pp_city_1;pp_country_1;pp_lastname_2;pp_firstname_2;pp_gender_2;pp_street_2;pp_postal_2;pp_city_2;pp_country_2;pp_phone;pp_email;ppp_sku;ppp_name;farbe;ppp_price;ppp_quantity;p_porto
end
