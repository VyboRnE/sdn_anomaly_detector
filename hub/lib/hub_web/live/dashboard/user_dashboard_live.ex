defmodule HubWeb.UserDashboardLive do
  use HubWeb, :live_view
  alias Hub.Sensors

  alias Hub.Accounts
  @impl true
  def mount(_params, %{"user_token" => user_token} = session, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    sensors = Sensors.list_sensors_by_user(user.id)
    selected_sensor = List.first(sensors)

    # Завантажуємо початкову статистику для обраного сенсора
    stats = load_stats(selected_sensor)

    {:ok,
     socket
     |> assign(:sensors, sensors)
     |> assign(:selected_sensor, selected_sensor)
     |> assign(:show_add_form, false)
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

  def handle_event("add_sensor", _params, socket) do
    {:noreply, assign(socket, :show_add_form, true)}
  end

  def handle_event(
        "save_sensor",
        %{"sensor" => %{"name" => name}},
        %{assigns: %{current_user: user}} = socket
      ) do
 IO.inspect(user)
    case Hub.Sensors.create_sensor(user, %{"name" => name}) do
      {:ok, _sensor} ->
        sensors = Hub.Sensors.list_sensors_by_user(user.id)
        {:noreply, assign(socket, sensors: sensors, show_add_form: false)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
