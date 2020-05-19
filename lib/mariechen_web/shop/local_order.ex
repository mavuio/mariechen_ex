defmodule MariechenWeb.Shop.LocalOrder do
  @default_tax 20
  alias MariechenWeb.Shop.LocalCheckout
  # alias Mariechen.Core.Schemas.ProductVariant
  alias Mariechen.Core.Schemas.SkuInOrders
  alias Mariechen.Repo
  alias Mariechen.Core.Stock
  alias Kandis.Order
  import MariechenWeb.MyHelpers
  import Kandis.KdHelpers

  import Ecto.Query, warn: false

  @behaviour Kandis.Order

  def create_lineitem_from_cart_item(%{type: "product"} = item) when is_map(item) do
    %{
      type: "product",
      amount: item.amount,
      single_price: item.price,
      total_price: item.total_price,
      title: item.title,
      subtitle: item.subtitle,
      sku: "#{item.sku}",
      taxrate: Decimal.new(@default_tax)
    }
  end

  def create_lineitem_from_cart_item(%{type: "promocode"} = item) when is_map(item) do
    if(Decimal.cmp(item.total_price, 0) == :lt) do
      %{
        type: "promocode",
        amount: item.amount,
        total_price: item.total_price,
        title: item.title,
        sku: item.promocode,
        taxrate: Decimal.new(item[:taxrate] || @default_tax)
      }
    else
      nil
    end
  end

  def apply_delivery_cost(
        %{lineitems: _lineitems, stats: _stats} = orderdata,
        %{pickup: "no"} = orderinfo
      )
      when is_map(orderinfo) do
    orderdata
    |> update_in([:lineitems], fn lineitems ->
      lineitems ++ [create_delivery_lineitem(orderdata, orderinfo)]
    end)
  end

  def apply_delivery_cost(orderdata, _orderinfo), do: orderdata

  def create_delivery_lineitem(orderdata, orderinfo) do
    delivery_type = orderinfo.delivery_type

    LocalCheckout.get_delivery_types(orderdata.lang)
    |> Enum.find(&(&1.key == delivery_type))
    |> case do
      nil ->
        %{
          type: "addon",
          total_price: "0",
          title: trans(orderdata.lang, "Shipping", "Zustellung"),
          subtitle: "",
          taxrate: Decimal.new(@default_tax)
        }

      dt ->
        %{
          type: "addon",
          total_price: dt.price,
          title: trans(orderdata.lang, "Shipping", "Zustellung"),
          subtitle: dt.name <> " - " <> dt.duration,
          taxrate: Decimal.new(@default_tax)
        }
    end
    |> pipe_when(
      Order.is_testorder?(orderdata, orderinfo),
      (fn a -> %{a | total_price: "0"} end).()
    )
  end

  def decrement_stock_for_sku(sku, amount, %_{} = order)
      when is_integer(amount) and is_binary(sku) do
    Repo.get_by(SkuInOrders, sku: sku, order_id: order.id)
    |> if_nil(%SkuInOrders{})
    |> SkuInOrders.changeset(%{
      "amount" => amount,
      "sku" => sku |> to_int(),
      "order_id" => order.id
    })
    |> Repo.insert_or_update()
  end

  def update_stock(_order) do
    Stock.update_effective_stock_for_all_products()
  end

  def finish_order(order) do
    if order.state == "paid" do
      invoice_pdf_path = Order.get_invoice_file(order.order_nr)

      if present?(invoice_pdf_path) do
        Order.set_state(order.order_nr, "invoice_generated")
      else
        raise "cannot generate invoice pdf !"
      end
    end

    order = Order.get_by_order_nr(order.order_nr)

    if order.state == "invoice_generated" do
      orderhtml = Order.get_orderhtml(order)
      invoice_pdf_path = Order.get_invoice_file(order.order_nr)

      MariechenWeb.Shop.Email.confirmation_mail(order, orderhtml, invoice_pdf_path)
      |> Bamboo.Email.to([order.orderinfo.email])
      |> Bamboo.Email.bcc(Elixir.Application.get_env(:mariechen, :config)[:shop_bcc_recipients])
      |> Mariechen.Mailer.deliver_now()

      Order.set_state(order.order_nr, "emails_sent")
    end
  end
end
