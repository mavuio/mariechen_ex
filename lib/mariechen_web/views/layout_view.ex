defmodule MariechenWeb.LayoutView do
  use MariechenWeb, :view

  def fix_language_link(html, conn) do
    current_link = get_current_link(conn.request_path)

    html
    |> String.replace("/de/shop/ss20/", "/ex/de/" <> current_link)
    |> String.replace("/shop/ss20/", "/ex/en/" <> current_link)
  end

  defp get_current_link(path) do
    path
    |> String.split("/", trim: true)
    |> tl()
    |> Enum.join("/")
  end
end
