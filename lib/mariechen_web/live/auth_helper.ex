defmodule MariechenWeb.Live.AuthHelper do
  require Logger

  import Phoenix.LiveView, only: [assign: 3, assign: 2]

  defmacro __using__(opts) do
    config = [otp_app: opts[:otp_app]]
    session_id_key = Pow.Plug.prepend_with_namespace(config, "auth")
    auth_check_interval = Keyword.get(opts, :auth_check_interval, :timer.seconds(10))

    config = [
      session_id_key: session_id_key,
      auth_check_interval: auth_check_interval
    ]

    quote do
      @config unquote(Macro.escape(config)) ++
                [
                  live_view_module: __MODULE__
                ]

      def mount_user(socket, session),
        do: unquote(__MODULE__).mount_user(socket, self(), session, @config)

      def handle_info(:pow_auth_ttl, socket),
        do: unquote(__MODULE__).handle_auth_ttl(socket, self(), @config)
    end
  end

  def mount_user(socket, pid, session, config) do
    Map.fetch(session, config[:session_id_key])
    |> case do
      :error ->
        socket

      {:ok, session_id} ->
        case credentials_by_session_id(session_id) do
          {user, meta} ->
            socket = socket |> assign(user: user, user_meta: meta)

            if Phoenix.LiveView.connected?(socket) do
              init_auth_check(pid)
            end

            socket

          _everything_else ->
            socket
        end
    end
  end

  defp init_auth_check(pid) do
    Process.send_after(pid, :pow_auth_ttl, 0)
  end

  def handle_auth_ttl(socket, pid, config) do
    _live_view_module = Pow.Config.get(config, :live_view_module)
    auth_check_interval = Pow.Config.get(config, :auth_check_interval)

    case session_id_by_credentials(socket.assigns[:credentials]) do
      nil ->
        #  Logger.info("[#{__MODULE__}] User session no longer active")

        {:noreply, socket |> assign(:credentials, nil)}

      _session_id ->
        #  Logger.info("[#{__MODULE__}] User session still active")

        Process.send_after(pid, :pow_auth_ttl, auth_check_interval)

        {:noreply, socket}
    end
  end

  defp session_id_by_credentials(nil), do: nil

  defp session_id_by_credentials({user, meta}) do
    all_user_session_ids =
      Pow.Store.CredentialsCache.sessions(
        [backend: Pow.Store.Backend.EtsCache],
        user
      )

    all_user_session_ids
    |> Enum.find(fn session_id ->
      {_, session_meta} = credentials_by_session_id(session_id)

      session_meta[:fingerprint] == meta[:fingerprint]
    end)
  end

  defp credentials_by_session_id(session_id) do
    Pow.Store.CredentialsCache.get(
      [backend: Pow.Store.Backend.EtsCache],
      session_id
    )
  end
end
