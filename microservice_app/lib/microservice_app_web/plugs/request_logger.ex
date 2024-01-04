defmodule MicroserviceAppWeb.Plugs.RequestLogger do
  alias IEx.App
  require Logger

  @remote_url Application.get_env(:microservice_app, :request_logger)[:remote_url]
  # auth token for remote post, this will always be configured and should be read as an env var
  @application_id Application.get_env(:microservice_app, :request_logger)[:application_id]


  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> log_request()
    |> log_response()
  end

  defp log_request(conn) do
    request_data = %{
      request: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        uri: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
        verb: conn.method,
        headers: conn.req_headers |> Enum.into(%{}),
        body: conn.body_params |> Jason.encode!()
      }
    }

    Logger.info("Request Data: #{Jason.encode!(request_data)}")
    conn
  end

  defp log_response(conn) do
    response_data = %{
      response: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: conn.status,
        headers: conn.resp_headers |> Enum.into(%{}),
        body: conn.resp_body |> Jason.encode!()
      },
      transaction_id: UUID.uuid4(),
      direction: "Incoming",
    }

    response = post_to_remote(response_data)
    Logger.info("Response: #{inspect(response)}")

    conn
  end

  defp post_to_remote(data) do
    body = Jason.encode!(data)
    Logger.info("Response Data: #{body}")
    headers = [
      {"Content-Type", "application/json"},
      {"X-Moesif-Application-Id", @application_id},
    ]

    HTTPoison.post(@remote_url, body, headers)
  end
end
