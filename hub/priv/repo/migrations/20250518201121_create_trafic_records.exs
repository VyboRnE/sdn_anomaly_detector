defmodule Hub.Repo.Migrations.CreateTrafficRecords do
  use Ecto.Migration

  def change do
    create table(:traffic_records) do
      add(:timestamp, :integer, null: false)
      add(:packet_count, :integer, null: false)
      add(:unique_src_ip_count, :integer, null: false)
      add(:proto_counter, :jsonb, null: false, default: "{}")
      add(:tcp_syn_count, :integer, null: false, default: 0)
      add(:top_dst_ports, {:array, {:array, :integer}}, null: false, default: [])

      add(:anomaly, :boolean, null: false, default: false)
      add(:cusum_anomaly, :boolean, null: false, default: false)
      add(:isolation_anomaly, :boolean, null: false, default: false)

      add(:sensor_id, references(:sensors, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:traffic_records, [:sensor_id]))
    create(index(:traffic_records, [:timestamp]))
  end
end
