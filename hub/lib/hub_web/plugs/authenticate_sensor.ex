defmodule MyAppWeb.Plugs.AuthenticateSensor do
  import Plug.Conn
  alias MyApp.Sensors

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         %{} = sensor <- Sensors.get_sensor_by_api_key(token) do
      assign(conn, :current_sensor, sensor)
    else
      _ ->
        conn
        |> send_resp(401, "Unauthorized sensor")
        |> halt()
    end
  end
end
