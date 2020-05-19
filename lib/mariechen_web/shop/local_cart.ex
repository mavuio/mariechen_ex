defmodule MariechenWeb.Shop.LocalCart do
  alias Mariechen.Core.Bags
  alias Mariechen.Core.Schemas.ProductVariant
  alias Mariechen.Repo
  import Ecto.Query, warn: false
  import Kandis.KdHelpers
  alias MariechenWeb.Shop.Promocodes

  def augment_cart_items(items, params) when is_list(items) do
    items
    |> Enum.map(fn a ->
      case Bags.get_bag_for_cart(a.sku |> Kandis.KdHelpers.to_int(), params) do
        nil ->
          nil

        bag ->
          item =
            a
            |> Map.merge(bag)

          item
          |> Map.put(:total_price, Decimal.mult(item.price, item.amount))
          |> Map.put(:url, "/#{params["lang"]}/shop/#{item.p_category}/#{item.p_url}")
          |> Map.put(:type, "product")
      end
    end)
    |> Enum.filter(&present?/1)
  end

  def augment_cart(cart_record, params) do
    cart_record
    |> Map.put(:lang, MariechenWeb.FrontendHelpers.lang_from_params(params))
    |> update_in([:items], fn items -> items |> augment_cart_items(params) end)
    |> count_totals(params)
    |> pipe_when(
      present?(cart_record[:promocodes]),
      Promocodes.augment_cart_with_promocodes(params)
      |> count_totals(params)
    )
  end

  def count_totals(cart_record, _params) do
    cart_record |> IO.inspect(label: "mwuits-debug 2020-03-24_13:59 ")

    stats =
      cart_record.items
      |> Enum.reduce(%{total_items: 0, total_price: "0"}, fn el, acc ->
        acc
        |> update_in([:total_items], fn val -> val + el.amount end)
        |> update_in([:total_price], fn val ->
          Decimal.add(val, el.total_price)
        end)
      end)

    cart_record
    |> Map.merge(stats)
  end

  def get_max_for_sku(sku) do
    pv_id = sku |> Kandis.KdHelpers.to_int()

    if pv_id do
      ProductVariant
      |> select([pv], pv.effective_stock)
      |> where([pv], pv.id == ^pv_id)
      |> Repo.one()
      |> Kandis.KdHelpers.if_empty(:infinity)
    else
      :infinity
    end
  end

  def get_carts(_params) do
    Kandis.VisitorSessionStore
    |> order_by([s], desc: :inserted_at)
    |> limit([s], 500)
    |> Repo.all()
    |> Enum.map(fn a ->
      stripe_record = Kandis.VisitorSession.get_value(a.sid, "checkout_stripe_data", %{})
      checkout_record = Kandis.VisitorSession.get_value(a.sid, "checkout", %{})

      a
      |> Map.put(:stripe_data, stripe_record)
      |> Map.put(:checkout_data, checkout_record)
    end)
    |> Enum.filter(fn a -> present?(a.checkout_data[:delivery_type]) end)
  end
end
