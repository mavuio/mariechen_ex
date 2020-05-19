defmodule MariechenWeb.Shop.Email do
  use Bamboo.Phoenix, view: MariechenWeb.Shop.EmailView
  import Kandis.KdHelpers

  def confirmation_mail(order, orderhtml, invoice_pdf_path) do
    base_email()
    |> subject("Order #{order[:order_nr]}")
    |> assign(:order, order)
    |> assign(:orderhtml, orderhtml)
    |> pipe_when(invoice_pdf_path, put_attachment(invoice_pdf_path))
    |> render(:confirmation_mail)
  end

  defp base_email do
    new_email()
    |> from("EVA BLUT<info@shop.mariechen.com>")
    |> put_header("Reply-To", "shop@mariechen.com")
    # This will use the "email.html.eex" file as a layout when rendering html emails.
    # Plain text emails will not use a layout unless you use `put_text_layout`
    |> put_html_layout({MariechenWeb.LayoutView, "email.html"})
  end
end
