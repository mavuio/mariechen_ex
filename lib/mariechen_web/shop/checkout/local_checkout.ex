defmodule MariechenWeb.Shop.LocalCheckout do
  @moduledoc false

  # alias Kandis.VisitorSession
  alias MariechenWeb.FrontendHelpers

  import Kandis.KdHelpers
  import MariechenWeb.MyHelpers

  @all_steps ~w(pickup address shipping_address deliverytype review confirm payment payment_return finished)

  def check_if_redirect(conn) do
    conn
  end

  def redirect_to_default_step(conn, params) do
    conn
    |> Phoenix.Controller.redirect(
      to:
        MariechenWeb.Router.Helpers.checkout_step_path(
          conn,
          :step,
          MariechenWeb.FrontendHelpers.lang_from_params(params),
          default_step(params)
        )
    )
    |> Plug.Conn.halt()
  end

  def get_cart_basepath(params) do
    MariechenWeb.Router.Helpers.cart_path(MariechenWeb.Endpoint, :step, params["lang"] || "en")
  end

  def default_step(_params) do
    @all_steps
    |> hd()
  end

  def get_link_for_step(context, step) when is_map(context) do
    MariechenWeb.Router.Helpers.checkout_step_path(
      MariechenWeb.Endpoint,
      :step,
      MariechenWeb.FrontendHelpers.lang_from_params(context),
      step
    )
  end

  def get_next_step_link(context, current_step) when is_map(context) do
    next_step =
      current_step
      |> get_next_step(context)

    if next_step do
      MariechenWeb.Router.Helpers.checkout_step_path(
        MariechenWeb.Endpoint,
        :step,
        MariechenWeb.FrontendHelpers.lang_from_params(context),
        next_step
      )
    else
      get_cart_link(context)
    end
  end

  def get_prev_step_link(context, current_step) do
    prev_step =
      current_step
      |> get_prev_step(context)

    if prev_step do
      MariechenWeb.Router.Helpers.checkout_step_path(
        MariechenWeb.Endpoint,
        :step,
        MariechenWeb.FrontendHelpers.lang_from_params(context),
        prev_step
      )
    else
      get_cart_link(context)
    end
  end

  def get_cart_link(context) do
    lang = MariechenWeb.FrontendHelpers.lang_from_params(context)

    MariechenWeb.Router.Helpers.cart_path(MariechenWeb.Endpoint, :step, lang)
  end

  def map_atoms_to_strings(nil), do: %{}

  def map_atoms_to_strings(map) when is_map(map) do
    map |> Map.new(fn {k, v} -> {to_string(k), v} end)
  end

  def extract_useful_vars_from_context(context) do
    changeset = context[:changeset]

    changes =
      case changeset do
        nil -> %{}
        %{changes: changes} -> changes
      end

    lang = FrontendHelpers.lang_from_params(context)

    %{lang: lang}
    |> pipe_when(context[:checkout_record], Map.merge(context[:checkout_record]))
    |> Map.merge(changes)

    # end
  end

  def get_steps(context) do
    steps = @all_steps

    vars = extract_useful_vars_from_context(context)

    remove_shipping_address =
      cond do
        vars[:pickup] == "yes" -> true
        vars[:pickup] == "no" and vars[:has_shipping_address] == "no" -> true
        true -> false
      end

    remove_deliverytype =
      cond do
        vars[:pickup] == "yes" -> true
        true -> false
      end

    steps
    |> pipe_when(remove_shipping_address, Enum.reject(&(&1 == "shipping_address")))
    |> pipe_when(remove_deliverytype, Enum.reject(&(&1 == "deliverytype")))
  end

  def get_next_step(current_step, context) when is_binary(current_step) do
    steps = get_steps(context)
    idx = Enum.find_index(steps, &(&1 == current_step))

    cond do
      idx >= length(steps) - 1 -> nil
      true -> steps |> Enum.at(idx + 1)
    end
  end

  def get_prev_step(current_step, context) when is_binary(current_step) do
    steps = get_steps(context)

    step =
      Enum.find_index(steps, &(&1 == current_step))
      |> case do
        0 ->
          nil

        idx ->
          steps |> Enum.at(idx - 1)
      end

    if step == "confirm" do
      get_prev_step(step, context)
    else
      step
    end
  end

  def create_ordercart(cart) when is_map(cart) do
    cart
  end

  def create_orderinfo(checkout_record) when is_map(checkout_record) do
    checkout_record
  end

  def get_shipping_country(orderinfo) when is_map(orderinfo) do
    if orderinfo[:delivery_type] == "delivery" do
      case orderinfo[:has_shipping_address] do
        "yes" -> orderinfo[:shipping_country]
        _ -> orderinfo[:country]
      end
    end

    nil
  end

  def get_delivery_types(lang \\ "en", countrycode \\ nil) do
    ~w(at_post eu_gls us_fedex_economy us_fedex_priority asia_post asia_fedex_priority)
    |> Enum.map(&get_delivery_type(&1, lang))
    |> filter_delivery_types_for_country(countrycode)
  end

  def filter_delivery_types_for_country(types, nil), do: types

  def filter_delivery_types_for_country(types, countrycode)
      when is_list(types) and is_binary(countrycode) do
    country = Countries.get(countrycode)

    cond do
      countrycode == "AT" ->
        Enum.filter(types, &String.starts_with?(&1.key, "at_"))

      country.eu_member ->
        Enum.filter(types, &String.starts_with?(&1.key, "eu_"))

      country.continent == "Asia" ->
        Enum.filter(types, &String.starts_with?(&1.key, "asia_"))

      country.subregion == "Northern America" ->
        Enum.filter(types, &String.starts_with?(&1.key, "us_"))

      true ->
        []
    end
  end

  def is_valid_country(country) do
    cond do
      country.eu_member ->
        true

      country.continent == "Asia" ->
        true

      country.subregion == "Northern America" ->
        true

      true ->
        false
    end
  end

  def get_countries_for_dropdown(lang_or_params) do
    FrontendHelpers.lang_from_params(lang_or_params)

    countries =
      Countries.all()
      |> Enum.filter(&is_valid_country/1)
      |> Enum.map(fn a ->
        name = a.name
        {name, a.alpha2}
      end)

    [{nil, nil}] ++ countries
  end

  def get_delivery_type(key, lang) do
    %{
      key: key,
      name: t(lang, "delivery_types.#{key}.name"),
      duration: t(lang, "delivery_types.#{key}.duration"),
      price: t(lang, "delivery_types.#{key}.price") |> to_dec()
    }
  end
end
