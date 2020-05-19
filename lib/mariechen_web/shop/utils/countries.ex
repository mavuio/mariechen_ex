defmodule MariechenWeb.Shop.Countries do
  @moduledoc false

  def get_country_name(nil), do: nil

  def get_country_name(code) do
    case Countries.get(code) do
      nil -> ""
      c -> c.name
    end
  end
end
