defmodule ElixirWeb.Plugs.VisitId do
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    visit_id =
      Plug.Conn.get_session(conn, :visit_id)
      |> IO.inspect(label: "visit_id: ➜  ")

    if is_nil(visit_id) do
      new_visit_id = generate_new_visit_id()

      conn
      |> Plug.Conn.put_session(:visit_id, new_visit_id)
      |> Plug.Conn.assign(:visit_id, new_visit_id)
    else
      conn |> Plug.Conn.assign(:visit_id, visit_id)
    end
  end

  def generate_new_visit_id(), do: Pow.UUID.generate()
end
