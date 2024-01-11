defmodule MicroserviceAppWeb.Plugs.RequestLogger do
  import Plug.Conn  # Import Plug.Conn to use its functions like `assign`
  alias IEx.App
  require Logger

  # we do not use compile time config, so no need to do anything here
  def init(_opts), do: :ok

  def call(conn, _opts) do
    Logger.info("Calling RequestLogger Plug")
    # Fetch runtime configuration
    config = Application.get_env(:microservice_app, MicroserviceAppWeb.Plugs.RequestLogger)

    conn
    |> log_request(config)
    |> register_before_send(fn conn ->
      # Logging the request URI and response status
      Logger.info("Response Status: #{conn.status}")
      log_response(conn, config)
    end)
  end

  defp log_request(conn, config) do
    request_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      uri: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
      verb: conn.method,
      headers: conn.req_headers |> Enum.into(%{}),
      body: conn.body_params
    }
    assign(conn, :request_data, request_data)
  end

  defp log_response(conn, config) do
    response_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: conn.status,
      headers: conn.resp_headers |> Enum.into(%{}),
      body: conn.resp_body |> IO.chardata_to_string |> Jason.decode!()
    }

    combined_data = %{
      request: conn.assigns[:request_data],
      response: response_data,
      transaction_id: UUID.uuid4(),
      direction: "Incoming"
    }

    MicroserviceAppWeb.EventBatcher.enqueue(combined_data)
    conn
  end

  def post_to_remote(batch, config) do
    Logger.info("Remote URL: #{config[:api_url]} Application ID: #{config[:application_id]}")
    body = Jason.encode!(batch)
    Logger.info("Post Event Batch: #{body}")
    headers = [
      {"Content-Type", "application/json"},
      {"X-Moesif-Application-Id", config[:application_id]},
    ]

    resp = HTTPoison.post(config[:api_url], body, headers)
    Logger.info("Response from Moesif: #{inspect(resp)}")
  end
end
