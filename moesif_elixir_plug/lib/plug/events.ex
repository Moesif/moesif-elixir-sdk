defmodule MoesifApi.Plug.EventLogger do
  alias ElixirSense.Log
  import Plug.Conn  # Import Plug.Conn to use its functions like `assign`
  require Logger

  # we do not use compile time config, so no need to do anything here
  def init(opts), do: opts

  def call(conn, opts) do
    # Fetch runtime configuration and merge with compile time config
    config = Enum.into(opts, default_config())
    Logger.info("Calling RequestLogger Plug with config #{inspect(config)}")

    conn
    |> log_request(config)
    |> register_before_send(fn conn -> log_response(conn, config) end)
  end

  defp default_config do
    [
      api_url: "https://api.moesif.net/v1",
      application_id: "Your Moesif Application ID Here",
      event_queue_size: 100_000,
      max_batch_size: 100,
      max_batch_wait_time_ms: 2_000
    ]
  end

  defp log_request(conn, config) do
    full_uri = URI.to_string(%URI{
      scheme: Atom.to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: conn.request_path,
      query: conn.query_string
    })
    Logger.debug("request.body_params #{inspect(conn.body_params)}")
    # if the body_params has the :all_nested special key "_json", then read that value; otherwise, use top-level body_params
    body = Map.get(conn.body_params, "_json", conn.body_params)


    # Safely fetch and call getter functions or default to nil
    user_id = safely_invoke_getter(config, :get_user_id, conn)
    company_id = safely_invoke_getter(config, :get_company_id, conn)

    event = %{
      request: %{
        time: DateTime.utc_now() |> DateTime.to_iso8601(),
        uri: full_uri,
        verb: conn.method,
        headers: conn.req_headers |> Enum.into(%{}),
        body: body
      },
      response: nil,
      user_id: user_id,
      company_id: company_id,
      session_token: nil,
      metadata: nil,
      transaction_id: UUID.uuid4(),
      direction: "Incoming"
    }
    assign(conn, :moesif_event, event)
  end

  defp log_response(conn, _config) do
    Logger.info("log_response")
    response_data = %{
      time: DateTime.utc_now() |> DateTime.to_iso8601(),
      status: conn.status,
      headers: conn.resp_headers |> Enum.into(%{}),
      body: conn.resp_body |> IO.chardata_to_string |> Jason.decode!()
    }
    event = conn.assigns[:moesif_event]
    event = Map.put(event, :response, response_data)
    Logger.info inspect(event, pretty: true)

    MicroserviceAppWeb.EventBatcher.enqueue(event)
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

  defp safely_invoke_getter(config, getter_key, conn) do
    case config[getter_key] do
      nil -> nil
      getter_fun when is_function(getter_fun, 1) -> getter_fun.(conn)
      _ -> nil
    end
  end

end
