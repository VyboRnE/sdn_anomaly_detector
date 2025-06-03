defmodule Hub.TrafficRecords.TrafficRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "traffic_records" do
    field(:timestamp, :integer)
    field(:packet_count, :integer)
    field(:unique_src_ip_count, :integer)
    field(:proto_counter, :map)
    field(:tcp_syn_count, :integer)
    field(:top_dst_ports, {:array, {:array, :integer}}) # масив масивів [port, count]
    field(:anomaly, :boolean, default: false)
    field(:cusum_anomaly, :boolean, default: false)
    field(:isolation_anomaly, :boolean, default: false)

    belongs_to(:sensor, Hub.Sensors.Sensor)

    timestamps()
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :timestamp,
      :packet_count,
      :unique_src_ip_count,
      :proto_counter,
      :tcp_syn_count,
      :top_dst_ports,
      :anomaly,
      :cusum_anomaly,
      :isolation_anomaly,
      :sensor_id
    ])
    |> validate_required([:timestamp, :sensor_id])
    |> foreign_key_constraint(:sensor_id)
  end
end
