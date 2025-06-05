defmodule HubWeb.UserDashboardLive do
  use HubWeb, :live_view
  alias Hub.Sensors

  alias Hub.Accounts
  alias Hub.TrafficRecords
  alias Phoenix.PubSub
  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    sensors = Sensors.list_sensors_by_user(user.id)
    selected_sensor = List.first(sensors)

    # Завантажуємо початкову статистику для обраного сенсора
    stats = load_stats(selected_sensor, "3")
    top_ports = load_top_ports(selected_sensor, "3")

    if connected?(socket) && selected_sensor,
      do: PubSub.subscribe(Hub.PubSub, "pubsub_refresh")

    {:ok,
     socket
     |> assign(sensors: sensors)
     |> assign(selected_sensor: selected_sensor)
     |> assign(show_add_form: false)
     |> assign(stats: stats)
     |> assign(top_ports: top_ports)
     |> assign(search_period: "3")}
  end

  defp load_stats(nil, _), do: %{}

  defp load_stats(sensor, search_period),
    do: TrafficRecords.get_sensor_stats(sensor.id, search_period)

  defp load_top_ports(nil, _), do: []

  defp load_top_ports(sensor, search_period) do
    sensor.id
    |> TrafficRecords.get_top_ports(search_period)
  end

  def handle_event("select_sensor", %{"sensor_id" => sensor_id}, socket) do
    sensor = Enum.find(socket.assigns.sensors, &(&1.id == String.to_integer(sensor_id)))

    stats = load_stats(sensor, socket.assigns.search_period)
    top_ports = load_top_ports(sensor, socket.assigns.search_period)

    {:noreply,
     socket
     |> assign(selected_sensor: sensor)
     |> assign(stats: stats)
     |> assign(top_ports: top_ports)}
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
        stats = load_stats(sensor, socket.assigns.search_period)
        top_ports = load_top_ports(sensor, socket.assigns.search_period)

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
    stats = load_stats(socket.assigns.selected_sensor, search_period)
    top_ports = load_top_ports(socket.assigns.selected_sensor, search_period)

    {:noreply,
     socket
     |> assign(:search_period, search_period)
     |> assign(:stats, stats)
     |> assign(:top_ports, top_ports)}
  end

  def handle_info(:refresh, socket) do
    stats = load_stats(socket.assigns.selected_sensor, socket.assigns.search_period)
    top_ports = load_top_ports(socket.assigns.selected_sensor, socket.assigns.search_period)

    {:noreply,
     socket
     |> assign(stats: stats)
     |> assign(top_ports: top_ports)}
  end
end
