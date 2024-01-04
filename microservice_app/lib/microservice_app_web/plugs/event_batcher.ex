defmodule MicroserviceAppWeb.EventBatcher do
  use GenServer

  @max_batch_size 3

  # Starts the GenServer
  def start_link(initial_state \\ []) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  # GenServer Callbacks
  def init(state), do: {:ok, state}

  # Public API to add data to the queue
  def enqueue(data) do
    GenServer.cast(__MODULE__, {:enqueue, data})
  end

  # GenServer handle_cast callback
  def handle_cast({:enqueue, data}, state) do
    new_state = [data | state]
    if length(new_state) >= @max_batch_size do
      send_batch(new_state)
      {:noreply, []}
    else
      {:noreply, new_state}
    end
  end

  defp send_batch(batch) do
    MicroserviceAppWeb.RequestLogger.post_to_remote(batch)
  end
end
