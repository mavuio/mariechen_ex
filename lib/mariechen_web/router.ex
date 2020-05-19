defmodule MariechenWeb.Router do
  use MariechenWeb, :router
  import Phoenix.LiveView.Router
  import Redirect

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_session
    plug ElixirWeb.Plugs.VisitId
  end

  pipeline :callback do
    plug Kandis.Plugs.FetchRequestBody
    plug :accepts, ["xml", "json"]

    # plug :fetch_session
    # plug :fetch_live_flash
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
    # plug :fetch_session
    # plug ElixirWeb.Plugs.VisitId
    # plug ElixirWeb.Plugs.DefaultParams
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug ElixirWeb.Plugs.VisitId
  end

  pipeline :require_beuser do
    plug ElixirWeb.Plugs.RequireBeUser
  end

  scope "/", MariechenWeb do
    pipe_through :callback

    post "/checkout/callback/:provider", Shop.Checkout.Controller, :callback
  end

  scope "/", MariechenWeb do
    pipe_through :browser

    get "/", PageController, :index

    match :*, "/:lang/cart", Shop.Checkout.Controller, :step,
      as: :cart,
      assigns: %{"step" => "cart"}

    get "/:lang/checkout", Shop.Checkout.Controller, :index, as: :checkout
    match :*, "/:lang/checkout/:step", Shop.Checkout.Controller, :step, as: :checkout_step
  end

  scope "/cartapi", MariechenWeb do
    pipe_through :api
    get "/add_to_cart/:sku", PageController, :add_to_cart
    get "/get_cart_count", PageController, :get_cart_count
  end

  redirect("/be", "/ex/be/orders", :permanent)

  scope "/be", MariechenWeb do
    pipe_through :browser
    pipe_through :require_beuser
    get "/carts", BackendController, :list_carts
    get "/cart/:sid", BackendController, :show_cart_data
    get "/orders", BackendController, :list_orders
    get "/order/:order_nr", BackendController, :show_order
    get "/invoice/:order_nr", BackendController, :show_invoice
    get "/invoicehtml/:order_nr", BackendController, :show_invoice_html
  end

  scope "/tags", MariechenWeb do
    pipe_through :api
    get "/get_tags_for_types", TagsController, :get_tags_for_types
    get "/get_tag_tree_for_types", TagsController, :get_tag_tree_for_types

    post "/get_tags_for_string", TagsController, :get_tags_for_string
    get "/get_tags_for_record/:record", TagsController, :get_tags_for_record
    post "/set_tags_for_record/:record", TagsController, :set_tags_for_record
    get "/touch_product_page/:id", TagsController, :touch_product_page
    get "/touch_product_variant/:id", TagsController, :touch_product_variant
    post "/update_tags/", TagsController, :update_tags_on_multiple_records
  end

  scope "/bags", MariechenWeb do
    pipe_through :api
    get "/list", BagsController, :list
    post "/list", BagsController, :list
    post "/count", BagsController, :count
    get "/update_stock", BagsController, :update_stock
    get "/get_beuser_token/:user_id", BackendController, :get_beuser_token
  end
end
