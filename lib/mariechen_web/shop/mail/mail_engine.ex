defmodule MariechenWeb.Shop.MailEngine do
  @moduledoc false

  alias Mariechen.Mailer
  import Bamboo.Email
  alias Kandis.KdPipeableLogger

  require Ecto.Query

  # import Kandis.KdHelpers

  def send_notification_mail(subject, text, recipient) do
    text = text <> "\nUTC-Time: " <> (DateTime.utc_now() |> DateTime.to_string())

    mail =
      Bamboo.Email.new_email()
      |> to([recipient])
      |> from({"EVA BLUT", "info@shop.mariechen.com"})
      |> subject(subject)
      |> text_body(text)
      |> Mailer.deliver_now()

    recipient |> KdPipeableLogger.info("mail #{subject} sent to")

    {:ok, mail}
  end

  def send_confirmation_mail(order_nr, recipient) when is_binary(recipient) do
    order = Kandis.Order.get_by_order_nr(order_nr)

    orderhtml = Kandis.Order.create_orderhtml(order.orderdata, order.orderinfo, order)

    MariechenWeb.Shop.Email.confirmation_mail(order, orderhtml, nil)
    |> Bamboo.Email.to([recipient])
    |> Mariechen.Mailer.deliver_now()

    # |> Bamboo.Email.bcc(Application.get_env(:mariechen, :config)[:shop_bcc_recipients])

    # cart = Cart.get_augmented_cart_record(userid, session)
    #  checkout_record = Kandis.Checkout.get_checkout_record(vid)

    # ordercart = Checkout.create_ordercart(cart, session["lang"])

    # orderinfo = Checkout.create_orderinfo(checkout_record)
    # orderdata = Order.create_orderdata(ordercart, orderinfo)
    # orderhtml = Order.create_orderhtml(orderdata, orderinfo)

    # mail =
    #   MariechenWeb.Shop.Email.confirmation_mail(order, orderhtml)
    #   |> to([recipient])
    #   |> Mailer.deliver_now()

    # # recipient |> KdPipeableLogger.info("confi sent to")

    # {:ok, mail}
  end
end
