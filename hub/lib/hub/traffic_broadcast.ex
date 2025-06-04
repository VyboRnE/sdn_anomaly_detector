defmodule Hub.TrafficBroadcast do
  use GenServer
  alias Phoenix.PubSub

  @interval :timer.minutes(1)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    schedule_broadcast()
    {:ok, %{}}
  end

  def handle_info(:broadcast, state) do
    PubSub.broadcast(Hub.PubSub, "pubsub_refresh", :refresh)

    schedule_broadcast()
    {:noreply, state}
  end

  defp schedule_broadcast() do
    Process.send_after(self(), :broadcast, @interval)
  end
end
