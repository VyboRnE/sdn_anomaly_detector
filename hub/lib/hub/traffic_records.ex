defmodule Hub.TrafficRecords do
  import Ecto.Query
  alias Hub.Repo
  alias Hub.TrafficRecords.TrafficRecord

  def get_sensor_stats(sensor_id, period) do
    interval = "minute"
    now_unix = Timex.now() |> Timex.to_unix()
    from_unix = now_unix - String.to_integer(period) * 3600

    base_query =
      from(tr in TrafficRecord,
        where: tr.sensor_id == ^sensor_id and tr.timestamp >= ^from_unix,
        select: %{
          truncated_time: fragment("date_trunc(?, to_timestamp(?))", ^interval, tr.timestamp),
          packet_count: tr.packet_count,
          unique_src_ip_count: tr.unique_src_ip_count,
          tcp_syn_count: tr.tcp_syn_count,
          anomaly: tr.anomaly,
          cusum_anomaly: tr.cusum_anomaly,
          isolation_anomaly: tr.isolation_anomaly,
          proto_counter: tr.proto_counter
        }
      )

    query =
      from(sq in subquery(base_query),
        group_by: sq.truncated_time,
        order_by: sq.truncated_time,
        select: %{
          time: sq.truncated_time,
          total_packet_count: sum(sq.packet_count),
          total_unique_src_ips: sum(sq.unique_src_ip_count),
          total_tcp_syn_count: sum(sq.tcp_syn_count),
          anomaly_count: fragment("SUM(CASE WHEN ? = TRUE THEN 1 ELSE 0 END)", sq.anomaly),
          cusum_anomaly_count:
            fragment("SUM(CASE WHEN ? = TRUE THEN 1 ELSE 0 END)", sq.cusum_anomaly),
          isolation_anomaly_count:
            fragment("SUM(CASE WHEN ? = TRUE THEN 1 ELSE 0 END)", sq.isolation_anomaly),
          proto_tcp_count: fragment("SUM(COALESCE((? ->> '6')::int, 0))", sq.proto_counter),
          proto_udp_count: fragment("SUM(COALESCE((? ->> '17')::int, 0))", sq.proto_counter),
          proto_icmp_count: fragment("SUM(COALESCE((? ->> '1')::int, 0))", sq.proto_counter)
        }
      )

    Repo.all(query)
  end

  def get_top_ports(sensor_id, period) do
    interval = "minute"
    now_unix = Timex.now() |> Timex.to_unix()
    from_unix = now_unix - String.to_integer(period) * 3600

    from(t in TrafficRecord,
      where: t.sensor_id == ^sensor_id and t.timestamp >= ^from_unix,
      group_by: t.top_dst_ports,
      select: %{port: t.top_dst_ports, count: count(t.id)},
      order_by: [desc: count(t.id)],
      limit: 10
    )
    |> Repo.all()
    |> Enum.flat_map(& &1.port)
    |> Enum.reduce(%{}, fn [port, count], acc ->
      Map.update(acc, port, count, &(&1 + count))
    end)
    |> Enum.map(fn {port, count} -> %{port: port, count: count} end)
    |> Enum.sort_by(& &1.count, :desc)
    |> Enum.take(10)
  end

  def store_report(sensor, attrs) do
    sensor
    |> Ecto.build_assoc(:traffic_records)
    |> TrafficRecord.changeset(attrs)
    |> Repo.insert()
  end
end
