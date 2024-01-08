defmodule MicroserviceAppWeb.EventBatcher do
  use GenServer
  require Logger

  @max_batch_size 3

  # Starts the GenServer
  def start_link(initial_state \\ []) do
    Logger.info("Starting EventBatcher GenServer")
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  # GenServer Callbacks
  def init(state), do: {:ok, state}

  # Public API to add data to the queue
  def enqueue(data) do
    Logger.info("Enqueueing data: #{inspect(data)}")
    GenServer.cast(__MODULE__, {:enqueue, data})
  end

  # GenServer handle_cast callback
  def handle_cast({:enqueue, data}, state) do
    Logger.info("Handling cast: #{inspect(data)}")
    new_state = [data | state]
    if length(new_state) >= @max_batch_size do
      Logger.info("Sending batch: #{inspect(new_state)}")
      send_batch(new_state)
      {:noreply, []}
    else
      Logger.info("Not sending batch of length #{length(new_state)}")
      {:noreply, new_state}
    end
  end

  defp send_batch(batch) do
    MicroserviceAppWeb.Plugs.RequestLogger.post_to_remote(batch)
  end
end
