defmodule MariechenWeb.MyHelpers do
  def format_price([]) do
    format_price(nil)
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

  def local_date(utc_date) do
    DateTime.from_naive(utc_date, "Etc/UTC")
    |> case do
      {:ok, date} ->
        DateTime.shift_zone(date, "Europe/Vienna")
        |> case do
          {:ok, date} ->
            DateTime.to_naive(date)

          _ ->
            utc_date
        end

      _ ->
        utc_date
    end
  end

  def format_date(utc_date) do
    utc_date
    |> local_date()
  end

  def trans(lang_or_params, txt_en, txt_de \\ nil) do
    case lang_from_params(lang_or_params) do
      "de" -> txt_de
      _ -> txt_en
    end
  end

  def t(lang_or_params, key, variables \\ []) do
    try do
      ExI18n.t(lang_from_params(lang_or_params), key, variables)
    rescue
      ArgumentError -> key
    end
  end

  def lang_from_params(lang_or_params) do
    case lang_or_params do
      map when is_map(lang_or_params) -> map["lang"] || map[:lang] || "en"
      str when is_binary(str) -> str
      _ -> "en"
    end
  end

  def get_invoice_template_url(order_nr) when is_binary(order_nr) do
    Elixir.Application.get_env(:kandis, :local_url) <>
      MariechenWeb.Router.Helpers.backend_path(
        MariechenWeb.Endpoint,
        :show_invoice_html,
        order_nr
      ) <>
      "?token=" <>
      MariechenWeb.BackendController.generate_beuser_token()
  end

  def get_pdf_template_url(order_nr, mode) when is_binary(order_nr) and is_binary(mode) do
    Elixir.Application.get_env(:kandis, :local_url) <>
      MariechenWeb.Router.Helpers.backend_path(
        MariechenWeb.Endpoint,
        :show_invoice_html,
        order_nr
      ) <>
      "?token=" <>
      MariechenWeb.BackendController.generate_beuser_token()
  end
end
