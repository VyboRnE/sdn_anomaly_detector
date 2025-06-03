defmodule Hub.Sensors.Sensor do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sensors" do
    field(:name, :string)
    field(:api_key, :string)
    belongs_to(:user, Hub.Accounts.User)

    has_many(:trafic_records, Hub.TrafficRecords.TrafficRecord)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sensor, attrs) do
    sensor
    |> cast(attrs, [:name, :api_key])
    |> validate_required([:name, :api_key])
    |> unique_constraint(:api_key)
  end
end
