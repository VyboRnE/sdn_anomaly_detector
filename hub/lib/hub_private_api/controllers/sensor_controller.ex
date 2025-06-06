defmodule HubPrivateAPI.Controllers.SensorController do
  use HubWeb, :controller

  alias Hub.Sensors
  alias Hub.Sensors.Sensor
  alias Hub.TrafficRecords

  @detector_url "http://0.0.0.0:10000/api/detect"

  def receive_data(conn, params) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] ->
        case Sensors.get_sensor_by_api_key(api_key) do
          nil ->
            send_resp(conn, 401, "Invalid API Key")

          %Sensor{} = sensor ->
            Task.start(fn ->
              forward_and_handle_anomalies(sensor, params)
            end)

            send_resp(conn, 202, "Accepted")
        end

      _ ->
        send_resp(conn, 401, "Missing API Key")
    end
  end

  defp forward_and_handle_anomalies(sensor, params) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{sensor.api_key}"}
    ]

    body = Jason.encode!(params)

    case HTTPoison.post(@detector_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{} = data} ->
            TrafficRecords.store_report(sensor, data)

          _ ->
            IO.warn("[!] Could not parse AI module response")
        end

      {:error, err} ->
        IO.inspect(err, label: "Error contacting AI module")

      err ->
        IO.inspect(err)
        IO.warn("[!] Unknown error from AI module")
    end
  end
end
