defmodule MariechenWeb.FrontendHelpers do
  use Phoenix.HTML

  # import Kandis.KdHelpers

  def body_classes(conn) do
    "c-#{Phoenix.Controller.controller_module(conn) |> Phoenix.Naming.resource_name("Controller")} a-#{
      Phoenix.Controller.action_name(conn)
    }"
  end

  def format_price([]) do
    format_price(nil)
  end

  def format_day(date) do
    :io_lib.format("~2..0B.~2..0B.~4..0B", [date.day, date.month, date.year])
    |> IO.iodata_to_binary()
  end

  def format_price(price, precision \\ 2) do
    res =
      price
      |> Number.Delimit.number_to_delimited(precision: precision, delimiter: ".", separator: ",")

    if Kandis.KdHelpers.present?(price) do
      # nbsp:
      "#{res}\u00A0€"
    else
      ""
    end
  end

  def wrap_at_dash(nil) do
    nil
  end

  def wrap_at_dash(str) do
    str |> String.replace("-", "<br>", global: false)
  end

  defdelegate local_date(utc_date), to: MariechenWeb.MyHelpers
  defdelegate format_date(utc_date), to: MariechenWeb.MyHelpers

  defdelegate trans(lang_or_params, txt_en, txt_de \\ nil), to: MariechenWeb.MyHelpers

  defdelegate t(lang_or_params, key), to: MariechenWeb.MyHelpers

  defdelegate lang_from_params(lang_or_params), to: MariechenWeb.MyHelpers
end
