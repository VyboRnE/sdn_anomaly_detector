defmodule MyAppWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns.current_user.role == "admin" do
      conn
    else
      conn
      |> put_flash(:error, "Access denied")
      |> redirect(to: "/")
      |> halt()
    end
  end
end
