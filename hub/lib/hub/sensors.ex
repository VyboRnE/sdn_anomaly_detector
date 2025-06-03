defmodule Hub.Sensors do
  import Ecto.Query

  alias Hub.Repo
  alias Hub.Sensors.Sensor
  alias Hub.Repo
  alias Hub.TrafficStat

  def list_sensors_by_user(user_id) do
    Repo.all(from(s in Sensor, where: s.user_id == ^user_id))
  end

  def get_sensor_by_api_key(api_key) do
    Repo.get_by(Sensor, api_key: api_key)
    |> Repo.preload(:user)
  end

  def list_sensors_by_user(user_id) do
    Repo.all(from(s in Sensor, where: s.user_id == ^user_id))
  end

  def create_sensor(user, attrs) do
    user
    |> Ecto.build_assoc(:sensors)|>IO.inspect
    |> Sensor.changeset(Map.put(attrs, "api_key", UUID.uuid4()))|> IO.inspect
    |> Repo.insert()
  end

  def get_traffic_stats(sensor_id) do
    # Приклад: збираємо трафік за останні 24 години по годинах
    query =
      from(ts in TrafficStat,
        where: ts.sensor_id == ^sensor_id and ts.inserted_at > ago(24, "hour"),
        select: {ts.inserted_at, ts.bytes_in, ts.bytes_out},
        order_by: ts.inserted_at
      )

    Repo.all(query)
  end
end
