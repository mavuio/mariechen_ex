defmodule MariechenWeb.Integration do
  @moduledoc false
  use Memoize

  defmemo get_layout_template(lang), expires_in: 3_600_000 do
    lang_prefix =
      case lang do
        "en" -> ""
        a -> "/" <> a
      end

    fetch_url(lang_prefix <> "/shop/ss20/ex_template?no_cache=1")
  end

  def fetch_url(url) do
    base_url = Application.get_env(:mariechen, :config)[:local_url]

    url =
      '#{base_url}#{url}'
      |> IO.inspect(label: "fetching url for integration ")

    {:ok, {_result, _headers, body}} =
      :httpc.request(:get, {url, []}, [{:autoredirect, false}], [])

    List.to_string(body)
  end

  def get_layout_parts(lang) do
    [top, rest] =
      get_layout_template(lang)
      |> String.split("</head>")

    [
      mid,
      bottom
    ] =
      rest
      |> String.split("###CONTENT###")

    %{top: top, mid: mid, bottom: bottom}
  end

  def layout_part(lang, mode) do
    layout_parts = get_layout_parts(lang)
    layout_parts[mode]
  end
end
