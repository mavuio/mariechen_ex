defmodule MariechenWeb.Shop.Checkout.Controller do
  use MariechenWeb, :controller

  alias Kandis.Checkout
  alias Kandis.Payment

  def index(conn, params) do
    conn |> Checkout.redirect_to_default_step(params)
  end

  def step(conn, params) do
    conn =
      conn
      |> Checkout.process(Map.merge(conn.assigns, params))

    if conn.halted do
      conn
    else
      conn =
        conn
        |> put_view(MariechenWeb.PageView)

      case conn.assigns[:live_module] do
        nil -> render(conn, conn.assigns[:template_name], params)
        module_name -> live_render(conn, module_name, session: params)
      end
    end
  end

  def callback(conn, params) do
    conn
    |> Payment.process_callback(Map.merge(conn.assigns, params))
  end
end
