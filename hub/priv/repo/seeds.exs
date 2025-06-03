# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hub.Repo.insert!(%Hub.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Hub.Repo
alias Hub.Accounts.User
alias Hub.Sensors.Sensor
alias Hub.TrafficRecords.TrafficRecord

# 1. Створення користувача
user =
  Repo.insert!(%User{
    email: "test@example.com",
    hashed_password: Bcrypt.hash_pwd_salt("password123")
  })

# 2. Створення сенсора
sensor =
  Repo.insert!(%Sensor{
    name: "Test Sensor 1",
    api_key: UUID.uuid4(),
    user_id: user.id
  })

# 3. Генерація фейкових traffic_records
Enum.each(1..100, fn i ->
  timestamp = Timex.now() |> Timex.shift(minutes: -i * 5) |> Timex.to_unix()

  proto_counter = %{
    "6" => Enum.random(300..400),
    "17" => Enum.random(50..100),
    "1" => Enum.random(10..30)
  }

  top_dst_ports = [
    [80, Enum.random(150..250)],
    [443, Enum.random(80..150)],
    [22, Enum.random(30..70)]
  ]

  Repo.insert!(%TrafficRecord{
    sensor_id: sensor.id,
    timestamp: timestamp,
    packet_count: Enum.random(400..600),
    unique_src_ip_count: Enum.random(80..120),
    proto_counter: proto_counter,
    tcp_syn_count: Enum.random(300..400),
    top_dst_ports: top_dst_ports,
    anomaly: Enum.random([true, false, false]),
    cusum_anomaly: Enum.random([true, false]),
    isolation_anomaly: Enum.random([true, false])
  })
end)

IO.puts("✅ Seeds вставлено: test@example.com / password123")
