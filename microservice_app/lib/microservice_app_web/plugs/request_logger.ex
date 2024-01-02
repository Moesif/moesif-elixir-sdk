defmodule MicroserviceAppWeb.Plugs.RequestLogger do
  require Logger

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
      },
      transaction_id: UUID.uuid4(),
      direction: "Incoming",
    }

    Logger.info("Request Data: #{Jason.encode!(request_data)}")
    conn
  end

  defp log_response(conn) do
    response_data = %{
      response: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        status: conn.status,
      }
    }

    Logger.info("Response Data: #{Jason.encode!(response_data)}")
    conn
  end
end
