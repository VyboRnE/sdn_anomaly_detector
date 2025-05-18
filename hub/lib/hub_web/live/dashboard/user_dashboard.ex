defmodule HubWeb.DashboardLive do
  use HubWeb, :live_view
  alias Hub.Sensors

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    # Завантажуємо сенсори користувача
    sensors = Sensors.list_sensors_by_user(user_id)
    selected_sensor = List.first(sensors)

    # Завантажуємо початкову статистику для обраного сенсора
    stats = load_stats(selected_sensor)

    {:ok,
     socket
     |> assign(:sensors, sensors)
     |> assign(:selected_sensor, selected_sensor)
     |> assign(:stats, stats)}
  end

  def handle_event("select_sensor", %{"sensor_id" => sensor_id}, socket) do
    sensor = Enum.find(socket.assigns.sensors, &(&1.id == String.to_integer(sensor_id)))
    stats = load_stats(sensor)

    {:noreply, assign(socket, selected_sensor: sensor, stats: stats)}
  end

  defp load_stats(nil), do: %{}

  defp load_stats(sensor) do
    # Тут витягуємо статистику трафіку для сенсора (з БД чи кешу)
    # Повертаємо у форматі, який зручно передавати графіку
    Sensors.get_traffic_stats(sensor.id)
  end
end
