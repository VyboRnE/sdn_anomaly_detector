defmodule Hub.Sensors do
  import Ecto.Query

  alias Hub.Repo
  alias Hub.Sensors.Sensor

  def list_sensors_by_user(user_id) do
    Repo.all(from(s in Sensor, where: s.user_id == ^user_id))
  end

  def get_sensor_by_api_key(api_key) do
    Repo.get_by(Sensor, api_key: api_key)
  end


  def create_sensor(user, attrs) do
    user
    |> Ecto.build_assoc(:sensors)
    |> Sensor.changeset(Map.put(attrs, "api_key", UUID.uuid4()))
    |> Repo.insert()
  end
end
