defmodule Hub.Sensors.Sensor do
  use Ecto.Schema
  import Ecto.Changeset
  alias Hub.Repo
  alias Hub.Sensors.Sensor
  alias Hub.TrafficStat

  schema "sensors" do
    field(:name, :string)
    field(:api_key, :string)
    belongs_to(:user, Hub.Accounts.User)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sensor, attrs) do
    sensor
    |> cast(attrs, [:name, :api_key])
    |> validate_required([:name, :api_key])
    |> unique_constraint(:api_key)
  end

  def get_sensor_by_api_key(api_key) do
    Repo.get_by(Sensor, api_key: api_key)
    |> Repo.preload(:user)
  end

  def list_sensors_by_user(user_id) do
    Repo.all(from(s in Sensor, where: s.user_id == ^user_id))
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
