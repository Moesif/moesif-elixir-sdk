defmodule MicroserviceAppWeb.EventBatcher do
  use GenServer
  require Logger

  def start_link(_opts) do
    # Fetch same Moesif runtime configuration as the RequestLogger Plug
    config = Application.get_env(:microservice_app, MicroserviceAppWeb.Plugs.RequestLogger)
    initial_state = %{config: config, data: []}
    Logger.info("Starting EventBatcher GenServer with config #{inspect(config)}")
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def enqueue(data) do
    GenServer.cast(__MODULE__, {:enqueue, data, :os.system_time(:millisecond)})
  end

  def handle_cast({:enqueue, data, enqueue_time}, %{config: config, data: []} = state) do
    # This is the first item in the batch, schedule a check
    Process.send_after(__MODULE__, :check_batch, config[:max_batch_wait_time_ms])
    new_data = [data]
    new_state = %{state | data: new_data}
    {:noreply, new_state}
  end

  def handle_cast({:enqueue, data, _enqueue_time}, %{config: config, data: current_data} = state) do
    new_data = [data | current_data]

    if length(new_data) >= config[:max_batch_size] do
      Logger.info("Sending batch: #{inspect(new_data)}")
      MicroserviceAppWeb.Plugs.RequestLogger.post_to_remote(new_data, config)
      new_state = %{state | data: []}
      {:noreply, new_state}
    else
      {:noreply, %{state | data: new_data}}
    end
  end

  def handle_info(:check_batch, %{config: config, data: current_data} = state) do
    if length(current_data) > 0 do
      Logger.info("Sending batch due to time limit: #{inspect(current_data)}")
      MicroserviceAppWeb.Plugs.RequestLogger.post_to_remote(current_data, config)
      {:noreply, %{state | data: []}}
    else
      {:noreply, state}
    end
  end

end
