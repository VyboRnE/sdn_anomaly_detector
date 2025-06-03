defmodule HubPrivateAPI.Controllers.SensorController do
  use HubWeb, :controller

  alias Hub.Sensors
  alias Hub.Sensors.Sensor
  alias Hub.Traffic

  @detector_url "http://detector-host:8000/api/sensor/submit"

  def submit(conn, %{"data" => packets}) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] ->
        case Sensors.get_sensor_by_api_key(api_key) do
          nil ->
            send_resp(conn, 401, "Invalid API Key")

          %Sensor{} = sensor ->
            Task.start(fn ->
              Traffic.store_packets(sensor.id, packets)
              forward_and_handle_anomalies(sensor, packets)
            end)

            send_resp(conn, 202, "Accepted")
        end

      _ ->
        send_resp(conn, 401, "Missing API Key")
    end
  end

  defp forward_and_handle_anomalies(sensor, packets) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{sensor.api_key}"}
    ]

    body = Jason.encode!(%{data: packets})

    case HTTPoison.post(@detector_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok,
           %{
             "cusum_anomaly" => cusum_anomaly,
             "isolation_anomalies" => isolation_anomalies,
             "total_packets" => total_packets
           }} ->
            Traffic.mark_anomalies(sensor.id, packets, isolation_anomalies)

          _ ->
            IO.warn("[!] Could not parse AI module response")
        end

      {:error, err} ->
        IO.inspect(err, label: "Error contacting AI module")

      _ ->
        IO.warn("[!] Unknown error from AI module")
    end
  end
end
