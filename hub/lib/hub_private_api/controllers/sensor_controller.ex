defmodule HubPrivateAPI.Controllers.SensorController do
  use HubWeb, :controller

  @detector_url "http://detector-host:8000/api/sensor/submit"

  def submit(conn, params) do
    Task.start(fn -> forward_to_detector(params) end)
    send_resp(conn, 202, "Accepted")
  end

  defp forward_to_detector(data) do
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(data)
    HTTPoison.post(@detector_url, body, headers)
  end
end
