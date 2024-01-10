defmodule MicroserviceAppWeb.Plugs.RequestLogger do
  import Plug.Conn  # Import Plug.Conn to use its functions like `assign`
  alias IEx.App
  require Logger

  @remote_url Application.get_env(:microservice_app, MicroserviceAppWeb.Plugs.RequestLogger)[:api_url]
  # auth token for remote post, this will always be configured and should be read as an env var
  @application_id Application.get_env(:microservice_app, MicroserviceAppWeb.Plugs.RequestLogger)[:application_id]


  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> log_request()
    |> log_response()
  end

  defp log_request(conn) do
    request_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      uri: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
      verb: conn.method,
      headers: conn.req_headers |> Enum.into(%{}),
      body: conn.body_params |> Jason.encode!()
    }
    Logger.info("Request Data: #{Jason.encode!(request_data)}")
    assign(conn, :request_data, request_data)
  end

  defp log_response(conn) do
    response_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: conn.status,
      headers: conn.resp_headers |> Enum.into(%{}),
      body: conn.resp_body |> Jason.encode!()
    }
    Logger.info("Response Data: #{Jason.encode!(response_data)}")

    combined_data = %{
      request: conn.assigns[:request_data],
      response: response_data,
      transaction_id: UUID.uuid4(),
      direction: "Incoming"
    }

    MicroserviceAppWeb.EventBatcher.enqueue(combined_data)
    conn
  end

  def post_to_remote(batch) do
    Logger.info("Remote URL: #{@remote_url}")
    body = Jason.encode!(batch)
    Logger.info("Post Event Batch: #{body}")
    headers = [
      {"Content-Type", "application/json"},
      {"X-Moesif-Application-Id", @application_id},
    ]

    resp = HTTPoison.post(@remote_url, body, headers)
    Logger.info("Response from Moesif: #{inspect(resp)}")
  end
end
