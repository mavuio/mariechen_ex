defmodule MariechenWeb.Shop.Promocodes do
  import Kandis.KdHelpers, warn: false
  import MariechenWeb.MyHelpers, warn: false
  alias Kandis.Cart
  alias Mariechen.Core.Bags

  def promocode_is_valid?(code, cart_record \\ %{})

  def promocode_is_valid?(code, cart_record)
      when is_binary(code) and is_map(cart_record) do
    get_promocode_record(code, cart_record)
    |> Map.get(:active) == true
  end

  def promocode_is_valid?(nil, _), do: false

  def get_promocode_record(code, params \\ %{})

  def get_promocode_record(code, params) when is_binary(code) do
    get_custom_promocode_record(code, params)
    |> case do
      nil ->
        %{active: false, reason: "not_found"}

      rec when is_map(rec) ->
        Map.merge(rec, %{active: promocode_record_is_active?(rec), code: code})
    end
  end

  def get_promocode_record(_, _) do
    nil
  end

  def get_custom_promocode_record("NEWSHOP10", params) do
    %{
      title: trans(params, "OPENING-special: 10% off", "OPENING-special: 10% Rabatt"),
      active_until: "2020-04-03",
      percentage_off: "10"
    }
  end

  def get_custom_promocode_record("OSTERN10", params) do
    %{
      title:
        trans(
          params,
          "Our Easter-Special: -10% for the new spring-summer-collection",
          "Ein Oster-Geschenk: -10% für alle Taschen der neuen Frühling-Sommer Kollektion"
        ),
      active_until: "2020-04-18",
      percentage_off: "10",
      product_tags: ["#ss20"]
    }
  end

  def get_custom_promocode_record(_, _), do: nil

  def promocode_record_is_active?(promocode_record) do
    case promocode_record do
      %{active_until: end_date} when is_binary(end_date) ->
        to_string(Date.utc_today()) <= end_date

      _ ->
        false
    end
  end

  def augment_cart_with_promocodes(cart_record, params) do
    Cart.get_promocodes(cart_record)
    |> Enum.reduce(cart_record, fn promocode, acc ->
      apply_promocode_to_cart(acc, promocode, params)
    end)
    |> IO.inspect(label: "mwuits-debug 2020-03-24_13:5A ")
  end

  def apply_promocode_to_cart(cart_record, promocode, params) do
    # fetch promocode
    promocode_record = get_promocode_record(promocode, params)

    if(promocode_record.active) do
      # create reduced prices
      cart_record =
        update_in(cart_record, [:items], &apply_promocode_to_cart_items(&1, promocode_record))

      # collect reduced prices
      promocode_record =
        promocode_record
        |> calculate_promocode_totals(cart_record, params)

      cart_record
      |> pipe_when(
        present?(promocode_record),
        Cart.add_item(promocode, promocode_record, :promocode)
      )
    else
      cart_record
    end
  end

  def apply_promocode_to_cart_items(cart_items, promocode_record)
      when is_list(cart_items) and is_map(promocode_record) do
    cart_items
    |> Enum.map(&apply_promocode_to_cart_item(&1, promocode_record))
  end

  def apply_promocode_to_cart_item(cart_item, promocode_record)
      when is_map(cart_item) and is_map(promocode_record) do
    reduction = get_promocode_reduction_for_cart_item(cart_item, promocode_record)

    case reduction do
      nil -> cart_item
      reduction -> cart_item |> apply_reduction_to_cart_item(reduction, promocode_record)
    end
  end

  def apply_reduction_to_cart_item(cart_item, reduction, promocode_record)
      when is_map(cart_item) and is_map(promocode_record) do
    price_reduced = Decimal.sub(cart_item.price, reduction)

    Map.merge(
      cart_item,
      %{
        price_reduced: price_reduced,
        total_price_reduced: Decimal.mult(price_reduced, cart_item.amount),
        total_reduction: Decimal.mult(reduction, cart_item.amount),
        promocode_applied: promocode_record.code
      }
    )
  end

  def get_promocode_reduction_for_cart_item(cart_item, promocode_record)
      when is_map(cart_item) and is_map(promocode_record) do
    if cart_item_is_eligble_for_promocode(cart_item, promocode_record) do
      cond do
        present?(promocode_record[:percentage_off]) ->
          Decimal.mult(
            Decimal.div(promocode_record[:percentage_off] |> to_dec(), 100),
            cart_item[:total_price]
          )

        true ->
          nil
      end
    else
      nil
    end
  end

  def get_promocode_reduction_for_cart_item(_, _), do: nil

  def cart_item_is_eligble_for_promocode(cart_item, promocode_record) do
    cond do
      present?(promocode_record[:product_tags]) ->
        Bags.bag_has_tags(cart_item.sku |> to_int(), promocode_record[:product_tags])

      true ->
        true
    end
  end

  # def apply_promocode_to_cart(cart_record, _, _params) do
  #   cart_record
  # end

  def calculate_promocode_totals(promocode_record, cart_record, _params) do
    reduced_total =
      Enum.reduce(cart_record.items, "0", fn a, total ->
        case a[:total_reduction] do
          nil -> total
          val -> Decimal.add(total, val)
        end
      end)

    price_to_add =
      case Decimal.eq?(reduced_total, "0") do
        true -> Decimal.new(0)
        false -> Decimal.mult(reduced_total, "-1")
      end

    promocode_record
    |> Map.put(:total_price, price_to_add)
    |> Map.put(:taxrate, 20)
  end
end
