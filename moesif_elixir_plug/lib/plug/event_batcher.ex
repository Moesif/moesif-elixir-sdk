defmodule MoesifApi.EventBatcher do
  use GenServer
  require Logger

  def start_link(opts) do
    config = MoesifApi.Config.fetch_config(opts)
    initial_state = %{config: config, data: []}
    Logger.info("Starting EventBatcher GenServer with config #{inspect(config)}")
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def enqueue(data) do
    GenServer.cast(__MODULE__, {:enqueue, data})
  end

  def handle_cast({:enqueue, data}, %{config: config, data: []} = state) do
    # This is the first item in the batch, schedule a check
    Process.send_after(__MODULE__, :check_batch, config[:max_batch_wait_time_ms])
    new_data = [data]
    new_state = %{state | data: new_data}
    {:noreply, new_state}
  end

  def handle_cast({:enqueue, data}, %{config: config, data: current_data} = state) do
    new_data = [data | current_data]

    if length(new_data) >= config[:max_batch_size] do
      Logger.info("Sending full batch of #{length(new_data)} events")
      post_to_remote(new_data, config)
      new_state = %{state | data: []}
      {:noreply, new_state}
    else
      {:noreply, %{state | data: new_data}}
    end
  end

  def handle_info(:check_batch, %{config: config, data: current_data} = state) do
    if length(current_data) > 0 do
      Logger.debug("Sending batch due to time limit: #{inspect(current_data)}")
      post_to_remote(current_data, config)
      {:noreply, %{state | data: []}}
    else
      {:noreply, state}
    end
  end

  def post_to_remote(batch, config) do
    Logger.info("Remote URL: #{config[:api_url]} Application ID: #{config[:application_id]}")
    body = Jason.encode!(batch)
    Logger.info("Post Event Batch: #{body}")
    headers = [
      {"Content-Type", "application/json"},
      {"X-Moesif-Application-Id", config[:application_id]},
    ]
    send_request(config[:api_url], body, headers)
  end

  defp send_request(url, body, headers) do
    Task.start(fn ->
      retry_post(url, body, headers, 3)
    end)
  end

  defp retry_post(url, body, headers, max_retries) do
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: code, body: response_body}} when code in 400..599 ->
        Logger.warn("Received #{code} response. Retrying... (#{max_retries} attempts left)")
        handle_retry(url, body, headers, max_retries, response_body)

      {:ok, resp} ->
        Logger.info("Response from Moesif: #{inspect(resp)}")

      {:error, _} = error ->
        Logger.warn("Failed to send request due to client error. Retrying... (#{max_retries} attempts left)")
        handle_retry(url, body, headers, max_retries, "Client error")
    end
  end

  defp handle_retry(url, body, headers, max_retries, last_error_msg) do
    if max_retries > 0 do
      sleep_time = round(:math.pow(2, 3 - max_retries) * 1000) + :rand.uniform(1000)
      Logger.info("Sleeping for #{sleep_time} ms before retrying...")
      :timer.sleep(sleep_time)
      retry_post(url, body, headers, max_retries - 1)
    else
      Logger.error("Failed to send request after maximum retries. Last error: #{last_error_msg}")
    end
  end
end
