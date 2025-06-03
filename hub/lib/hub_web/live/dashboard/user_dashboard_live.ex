defmodule HubWeb.UserDashboardLive do
  use HubWeb, :live_view
  alias Hub.Sensors

  alias Hub.Accounts
  alias Hub.TrafficRecords
  @impl true
  def mount(_params, %{"user_token" => user_token} = session, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    sensors = Sensors.list_sensors_by_user(user.id)
    selected_sensor = List.first(sensors)

    # Завантажуємо початкову статистику для обраного сенсора
    stats = load_stats(selected_sensor)
    top_ports = load_top_ports(selected_sensor)

    {:ok,
     socket
     |> assign(sensors: sensors)
     |> assign(selected_sensor: selected_sensor)
     |> assign(show_add_form: false)
     |> assign(stats: stats)
     |> assign(top_ports: top_ports)
     |> assign(search_period: "24h")}
  end

  defp load_stats(nil), do: %{}

  defp load_stats(sensor), do: TrafficRecords.get_sensor_stats(sensor.id)

  defp load_top_ports(nil), do: []

  defp load_top_ports(sensor) do
    sensor.id
    |> TrafficRecords.get_top_ports()
    |> Enum.flat_map(& &1.port)
    |> Enum.reduce(%{}, fn [port, count], acc ->
      Map.update(acc, port, count, &(&1 + count))
    end)
    |> Enum.map(fn {port, count} -> %{port: port, count: count} end)
    |> Enum.sort_by(& &1.count, :desc)
    |> Enum.take(10)
  end

  def handle_event("select_sensor", %{"sensor_id" => sensor_id}, socket) do
    sensor = Enum.find(socket.assigns.sensors, &(&1.id == String.to_integer(sensor_id)))
    stats = load_stats(sensor)
    top_ports = load_top_ports(sensor)

    {:noreply,
     socket
     |> assign(selected_sensor: sensor)
     |> assign(stats: stats)
     |> assign(:top_ports, top_ports)}
  end

  def handle_event("add_sensor", _params, socket) do
    {:noreply, assign(socket, :show_add_form, true)}
  end

  def handle_event(
        "save_sensor",
        %{"sensor" => %{"name" => name}},
        %{assigns: %{current_user: user}} = socket
      ) do
    case Hub.Sensors.create_sensor(user, %{"name" => name}) do
      {:ok, sensor} ->
        sensors = Hub.Sensors.list_sensors_by_user(user.id)
        stats = load_stats(sensor)
        top_ports = load_top_ports(sensor)

        {:noreply,
         socket
         |> assign(sensors: sensors)
         |> assign(selected_sensor: sensor)
         |> assign(stats: stats)
         |> assign(:top_ports, top_ports)
         |> assign(show_add_form: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("change_period", %{"period" => search_period}, socket) do
    stats = get_filtered_stats(socket.assigns.selected_sensor.id, search_period) || []

    {:noreply,
     socket
     |> assign(:search_period, search_period)
     |> assign(:stats, stats)
     |> assign(:top_ports, extract_top_ports(stats))}
  end
end
