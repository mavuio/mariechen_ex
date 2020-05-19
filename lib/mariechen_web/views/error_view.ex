defmodule MariechenWeb.ErrorView do
  use MariechenWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  def render("500.html", assigns) do
    message =
      case assigns.reason do
        %_{message: message} -> message
        e -> inspect(e)
      end

    render(
      __MODULE__,
      "server_error.html",
      Map.merge(assigns, %{
        layout: {MariechenWeb.LayoutView, "app.html"},
        lang: "en",
        message: message
      })
    )
  end
end
